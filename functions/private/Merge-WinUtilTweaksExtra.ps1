function Merge-WinUtilTweaksExtra {
    <#

    .SYNOPSIS
        Adds the fork's own tweaks from config/tweaksextra.json to $sync.configs.tweaks

    .DESCRIPTION
        Called once from scripts/main.ps1 right after the configs load, so the extra tweaks are
        known before -Config/-Preset validate selection keys and before the tweaks tab builds its
        controls. From then on they behave exactly like entries in tweaks.json.

        An ID that tweaks.json already defines is never overridden: it is skipped with a warning.
        Calling the function again is harmless; entries it already added are left alone.

    #>

    if ($null -eq $sync.configs.tweaksextra -or $null -eq $sync.configs.tweaks) {
        return
    }

    foreach ($property in $sync.configs.tweaksextra.PSObject.Properties) {
        $existing = $sync.configs.tweaks.PSObject.Properties[$property.Name]

        if ($null -ne $existing) {
            if (-not [object]::ReferenceEquals($existing.Value, $property.Value)) {
                Write-WinUtilLog -Level "WARN" -Component "Config" -Message "tweaksextra.json entry '$($property.Name)' already exists in tweaks.json and was skipped."
            }
            continue
        }

        $sync.configs.tweaks | Add-Member -MemberType NoteProperty -Name $property.Name -Value $property.Value
    }
}
