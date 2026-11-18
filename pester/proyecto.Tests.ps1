#===========================================================================
# Tests - Fork: tweaksextra.json merge and perfil.json contents (PROYECTO.md §3.2, §6, §9)

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $script:configRoot = Join-Path $script:repoRoot "config"
    $script:functionRoot = Join-Path $script:repoRoot "functions"
    $script:mainScript = Get-Content -Path (Join-Path $script:repoRoot "scripts\main.ps1") -Raw

    . (Join-Path $script:functionRoot "private\Merge-WinUtilTweaksExtra.ps1")
    . (Join-Path $script:functionRoot "private\Update-WinUtilSelections.ps1")

    # Stub so the merge can log without the logging pipeline; tests read what it recorded
    function Write-WinUtilLog {
        param($Level, $Component, $Message, [switch]$Detail)
        $script:loggedWarnings.Add("$Level|$Message")
    }

    function script:Read-ForkConfig {
        param([string]$Name)
        Get-Content -Path (Join-Path $script:configRoot "$Name.json") -Raw | ConvertFrom-Json
    }

    # PowerShell 5.1 returns a JSON array as one object; piping it unrolls the elements
    function script:Read-ForkPerfil {
        Get-Content -Path (Join-Path $script:configRoot "perfil.json") -Raw | ConvertFrom-Json | ForEach-Object { $_ }
    }

    # Builds $sync the way Compile.ps1 and main.ps1 do: applications keyed as WPFInstall<key>
    function script:New-ForkSync {
        $applicationsHashtable = @{}
        (Read-ForkConfig "applications").PSObject.Properties | ForEach-Object {
            $applicationsHashtable["WPFInstall$($_.Name)"] = $_.Value
        }
        $appxHashtable = @{}
        (Read-ForkConfig "appx").PSObject.Properties | ForEach-Object {
            $appxHashtable[$_.Name] = $_.Value
        }

        $global:sync = [hashtable]::Synchronized(@{})
        $global:sync.configs = @{
            tweaks               = Read-ForkConfig "tweaks"
            tweaksextra          = Read-ForkConfig "tweaksextra"
            feature              = Read-ForkConfig "feature"
            applicationsHashtable = $applicationsHashtable
            appxHashtable        = $appxHashtable
        }
        foreach ($listName in @("selectedApps", "selectedTweaks", "selectedToggles", "selectedFeatures", "selectedAppx")) {
            $global:sync[$listName] = [System.Collections.Generic.List[string]]::new()
        }
    }

    $script:loggedWarnings = [System.Collections.Generic.List[string]]::new()
}

Describe "tweaksextra.json merge hook" {
    BeforeEach {
        $script:loggedWarnings = [System.Collections.Generic.List[string]]::new()
    }

    It "runs in main.ps1 before -Config/-Preset validate keys and before the window is built" {
        $mergeAt = $script:mainScript.IndexOf("Merge-WinUtilTweaksExtra")
        $headlessAt = $script:mainScript.IndexOf('if ($Preset -or $Config) {')
        $uiAt = $script:mainScript.IndexOf("Start-WinUtilUserInterface")

        $mergeAt | Should -BeGreaterThan -1
        $headlessAt | Should -BeGreaterThan $mergeAt
        $uiAt | Should -BeGreaterThan $mergeAt
    }

    It "adds every tweaksextra entry and keeps every tweaks.json entry" {
        New-ForkSync
        $originalNames = @($sync.configs.tweaks.PSObject.Properties.Name)
        $extraNames = @($sync.configs.tweaksextra.PSObject.Properties.Name)

        Merge-WinUtilTweaksExtra

        $mergedNames = @($sync.configs.tweaks.PSObject.Properties.Name)
        foreach ($name in $originalNames + $extraNames) {
            $mergedNames | Should -Contain $name
        }
        $mergedNames.Count | Should -Be ($originalNames.Count + $extraNames.Count)
        $script:loggedWarnings.Count | Should -Be 0
    }

    It "does not override a tweaks.json entry with the same ID and logs a warning" {
        $global:sync = @{
            configs = @{
                tweaks      = [pscustomobject]@{ WPFTweaksSame = [pscustomobject]@{ Content = "WinUtil" } }
                tweaksextra = [pscustomobject]@{ WPFTweaksSame = [pscustomobject]@{ Content = "Fork" } }
            }
        }

        Merge-WinUtilTweaksExtra

        $sync.configs.tweaks.WPFTweaksSame.Content | Should -Be "WinUtil"
        $script:loggedWarnings | Should -HaveCount 1
        $script:loggedWarnings[0] | Should -BeLike "WARN|*WPFTweaksSame*"
    }

    It "is harmless when called twice" {
        New-ForkSync
        Merge-WinUtilTweaksExtra
        $countAfterFirst = @($sync.configs.tweaks.PSObject.Properties).Count

        Merge-WinUtilTweaksExtra

        @($sync.configs.tweaks.PSObject.Properties).Count | Should -Be $countAfterFirst
        $script:loggedWarnings.Count | Should -Be 0
    }
}

Describe "tweaksextra.json entries" {
    It "do not reuse an ID from tweaks.json" {
        $tweakNames = @((Read-ForkConfig "tweaks").PSObject.Properties.Name)
        $clashes = @((Read-ForkConfig "tweaksextra").PSObject.Properties.Name | Where-Object { $tweakNames -contains $_ })
        $clashes | Should -BeNullOrEmpty
    }

    It "carry the WinUtil fields plus Origen, Riesgo and a reversible registry schema" {
        $invalid = [System.Collections.Generic.List[string]]::new()

        foreach ($entry in (Read-ForkConfig "tweaksextra").PSObject.Properties) {
            if ($entry.Name -notlike "WPFTweaks*" -and $entry.Name -notlike "WPFToggle*") {
                $invalid.Add("$($entry.Name): ID must start with WPFTweaks or WPFToggle")
            }
            foreach ($field in @("Content", "Description", "category", "panel", "link", "Origen", "Riesgo")) {
                if ([string]::IsNullOrWhiteSpace([string]$entry.Value.$field)) {
                    $invalid.Add("$($entry.Name): missing $field")
                }
            }
            if (@("bajo", "medio", "alto") -notcontains $entry.Value.Riesgo) {
                $invalid.Add("$($entry.Name): Riesgo must be bajo, medio or alto")
            }
            if ($entry.Value.PSObject.Properties.Name -contains "Condicion" -and
                [string]$entry.Value.Condicion -notmatch '^(GPU|CPU|Equipo):\S+$') {
                $invalid.Add("$($entry.Name): Condicion must look like 'GPU:NVIDIA'")
            }
            foreach ($registryEntry in @($entry.Value.registry)) {
                if ($null -eq $registryEntry) { continue }
                foreach ($field in @("Path", "Name", "Type", "Value", "OriginalValue")) {
                    if ([string]::IsNullOrWhiteSpace([string]$registryEntry.$field)) {
                        $invalid.Add("$($entry.Name),registry $($registryEntry.Name): missing $field")
                    }
                }
            }
        }

        $invalid | Should -BeNullOrEmpty
    }

    It "do not claim a tweaks.json registry value with a different original or type" {
        $claims = @{}
        foreach ($source in @("tweaks", "tweaksextra")) {
            foreach ($tweak in (Read-ForkConfig $source).PSObject.Properties) {
                foreach ($registryEntry in @($tweak.Value.registry)) {
                    if ($null -eq $registryEntry -or $registryEntry.Values) { continue }
                    $key = "$($registryEntry.Path)|$($registryEntry.Name)"
                    if (-not $claims.ContainsKey($key)) { $claims[$key] = @{} }
                    $claims[$key]["$source/$($tweak.Name)"] = "$($registryEntry.OriginalValue)|$($registryEntry.Type)"
                }
            }
        }

        $conflicts = @($claims.Keys | Where-Object { @($claims[$_].Values | Select-Object -Unique).Count -gt 1 } | ForEach-Object {
            "$_ claimed by $((($claims[$_].Keys) | Sort-Object) -join ', ')"
        })
        $conflicts | Should -BeNullOrEmpty
    }
}

Describe "perfil.json" {
    It "is a flat array of unique IDs" {
        $perfil = @(Read-ForkPerfil)
        $perfil.Count | Should -BeGreaterThan 0
        @($perfil | Select-Object -Unique).Count | Should -Be $perfil.Count
        foreach ($id in $perfil) { $id | Should -BeOfType [string] }
    }

    It "names only IDs that exist once tweaksextra.json is merged, as -Config validates them" {
        New-ForkSync
        Merge-WinUtilTweaksExtra
        $perfil = [string[]]@(Read-ForkPerfil)

        # Without -SkipUnknown this throws on the first unknown key, exactly like -Config does
        { Update-WinUtilSelections -flatJson $perfil -Replace } | Should -Not -Throw

        $selected = @("selectedApps", "selectedTweaks", "selectedToggles", "selectedFeatures", "selectedAppx") |
            ForEach-Object { @($sync[$_]) }
        $selected.Count | Should -Be $perfil.Count
    }

    It "would fail -Config without the merge, so the hook is what makes the extra tweaks usable" {
        $extraInPerfil = @(Read-ForkPerfil) |
            Where-Object { (Read-ForkConfig "tweaksextra").PSObject.Properties.Name -contains $_ }
        if (-not $extraInPerfil) {
            Set-ItResult -Skipped -Because "perfil.json does not use any tweaksextra.json entry"
            return
        }

        New-ForkSync
        { Update-WinUtilSelections -flatJson ([string[]]$extraInPerfil) -Replace } | Should -Throw "*Unknown selection key*"
    }
}
