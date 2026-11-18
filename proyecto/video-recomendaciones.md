# Recomendaciones del video

Video: https://youtu.be/yKydZFJRzMk (Chris Titus)
Regla (PROYECTO.md §6.1): todo lo que el video recomienda va a `config/perfil.json`, **salvo** los ítems de seguridad de PROYECTO.md §7, que quedan como opción desmarcada.

Estado: **cerrada**. Revisada por el usuario y aplicada a `config/perfil.json` (etapa 1 de PROYECTO.md §11). Decisiones al final, en "Resultado".

Video: "Windows Utility in 2026 - Everything You Need to Know", subido el 17/02/2026, 14:45 min. Es un recorrido por la interfaz de WinUtil más que una guía de optimización: las recomendaciones concretas son pocas.

---

## Paso 1 — Bajar el material (sin el video)

```powershell
winget install --id yt-dlp.yt-dlp -e
New-Item -ItemType Directory -Force proyecto\fuentes\video | Out-Null
yt-dlp --skip-download --write-subs --write-auto-subs --sub-langs "en.*,es.*" --sub-format vtt `
       --write-description --write-info-json `
       -o "proyecto/fuentes/video/%(id)s.%(ext)s" "https://youtu.be/yKydZFJRzMk"
```

- Los subtítulos (`.vtt`) tienen lo que se dice.
- `.info.json` trae el título, la fecha y los **capítulos** (`chapters`), útiles para ordenar la tabla.
- `.description` puede traer links y comandos que se mencionan.
- Todo queda en `proyecto/fuentes/`, que no se sube a git.

## Paso 2 — Lo que solo se ve en pantalla

Los subtítulos no muestran qué casillas tilda en WinUtil ni qué opciones marca en otros programas. Cuando el texto diga algo como "check these", "select this" o "I'm going to enable…" sin nombrar el ítem, anotar el minuto en la sección **Capturas necesarias** y pedirle al usuario capturas de esos momentos.

## Paso 3 — Completar la tabla

Para cada recomendación:
1. Escribirla con palabras propias (no copiar frases largas de la transcripción).
2. Buscar si ya existe en WinUtil, por nombre y por descripción, en `config/tweaks.json`, `config/feature.json`, `config/applications.json` y `config/appx.json`. Para apps, el ID del perfil es `WPFInstall<clave>` (ej. `WPFInstall7zip`).
3. Asignar el destino:
   - `existente`: ya está en WinUtil → va al perfil con su ID.
   - `nuevo`: no existe → se crea en `config/tweaksextra.json` en la etapa 5 y después va al perfil.
   - `seguridad`: está en la lista de PROYECTO.md §7 → **no** va al perfil; se marca "recomendado en el video" en la pantalla de Seguridad.
   - `manual`: BIOS, panel de la GPU, hardware → checklist del reporte final.
   - `no aplica`: opinión o contexto.
4. Si es un ítem que WinUtil tiene en `z__Advanced Tweaks - CAUTION` pero **no** está en §7, igual va al perfil. Anotarlo en "Notas".

## Paso 4 — Revisión del usuario

Mostrar la tabla completa al usuario **antes** de modificar `config/perfil.json`. Recién con su visto bueno:
- agregar a `perfil.json` todos los IDs `existente`;
- quitar del perfil provisorio lo que el video desaconseje explícitamente (si lo hay);
- dejar los `nuevo` listados para la etapa 5;
- confirmar que ningún ID de seguridad quedó en `perfil.json`.

---

## Tabla

Destino `condicional`: el video lo recomienda solo para un caso puntual ("si tenés X", "si te gusta"). No es ninguno de los destinos de PROYECTO.md §6.1; la propuesta es dejarlo en el catálogo, desmarcado, y que el usuario decida.

| # | Minuto | Recomendación | Destino | ID | Notas |
|---|---|---|---|---|---|
| 1 | 00:22 | Ejecutar WinUtil desde una terminal como administrador con `irm christitus.com/win \| iex` | no aplica | — | El fork distribuye su propio `.ps1` (§10). |
| 2 | 01:02 | Instalar con la pestaña Install (winget) los programas que uno use | no aplica | — | No recomienda ninguna app concreta. 7-Zip y VC++ del perfil vienen del plan, no del video. |
| 3 | 02:35 | No tildar todo: los "Advanced Tweaks - CAUTION" no son para usuarios comunes | no aplica | — | Criterio general. Coincide con §6.1 (lo no mencionado queda desmarcado). |
| 4 | 02:46 | Bloquear la instalación automática del software de Razer, solo si se tienen periféricos Razer | condicional | `WPFTweaksRazerBlock` | Está en `z__Advanced Tweaks - CAUTION`. Depende del hardware. |
| 5 | 03:18 | Para la mayoría de los usuarios: aplicar "Standard Tweaks" | existente | IDs del preset `Standard` | Ver "Preset Standard: video vs. hoy". Ya están en `perfil.json`. |
| 6 | 03:20 | Crear un punto de restauración antes de aplicar | existente | `WPFTweaksRestorePoint` | Forma parte de Standard. Además es la fase 0 del motor. |
| 7 | 03:29 | Para revertir: Restaurar sistema o "Undo selected tweaks" | no aplica | — | Coincide con el principio 4 (todo reversible). |
| 8 | 03:49 | Disk Cleanup (parte de Standard) puede tardar de 30 min a 2 h en equipos con años de uso | existente | `WPFTweaksDiskCleanup` | En la demo lo saltea por tiempo, no lo desaconseja. En una PC recién formateada debería ser corto. Avisarlo en el resumen previo. |
| 9 | 04:32 | Standard deja unos 70-80 procesos en un sistema nuevo sin romper herramientas de Microsoft | no aplica | — | Contexto. |
| 10 | 05:02 | Usar los paneles clásicos: Panel de control, Impresoras, Sonido | no aplica | `WPFPanelControl`, `WPFPanelPrinter`, `WPFPanelSound` | Solo abren ventanas, no cambian nada. |
| 11 | 05:38 | Instalar el perfil de PowerShell de CTT, "si te gusta" | condicional | `WPFWinUtilInstallPSProfile` | Requiere PowerShell 7. Su prefijo no es un ID de selección: `-Config` no lo aplica. |
| 12 | 05:46 | Activar features de Windows como .NET Framework si se necesitan | condicional | `WPFFeaturesdotnet` | Lo da como ejemplo. Muchos juegos y programas viejos piden .NET 3.5. |
| 13 | 05:55 | Montar unidades NFS en lugar de SMB | no aplica | — | Uso personal y avanzado. |
| 14 | 06:07 | Reparación solo si hay problemas: reset de red, reset de Windows Update, SFC/DISM, reparar winget | no aplica | — | Son para diagnosticar, no para una instalación nueva. Sobre SFC/DISM dice que rara vez arreglan algo. |
| 15 | 07:31 | Windows Update en "Security settings": actualizaciones de funciones diferidas 365 días, de calidad 4 días, sin drivers por Windows Update | existente (botón) | `WPFUpdatessecurity` | La recomienda con énfasis, sobre todo en Windows Pro. §7 permite que vaya al perfil. **No es un ID de selección**: `Update-WinUtilSelections` rechaza IDs desconocidos, así que ponerlo en `perfil.json` rompería `-Config`. Se replicó como `WPFTweaksWindowsUpdateDefer` y `WPFTweaksWindowsUpdateNoDrivers` (ver "Resultado"). |
| 16 | 08:24 | Desactivar las actualizaciones solo ante una actualización rota, y reactivarlas después | seguridad | `WPFUpdatesdisable` | §7. No va al perfil. Advierte que no actualizar por mucho tiempo es inseguro aunque haya antivirus. |
| 17 | 09:06 | "Default updates" devuelve Windows Update a la configuración original | no aplica | `WPFUpdatesdefault` | Es el deshacer de 15 y 16. Usarlo en el reporte final como forma de revertir 15. |
| 18 | 10:48 | Para instalar Windows desde cero: MicroWin (ahora proyecto aparte), Tiny11 Builder o NTLite | no aplica | — | Fuera del alcance. Para la fase 0 externa (§8) seguimos con `autounattend.xml`. |
| 19 | 12:42 | Adelanto de una versión .NET offline de WinUtil | no aplica | — | Contexto. |

### Preset Standard: video vs. hoy

El preset cambió después del video. Contenido de `config/preset.json` a la fecha del video (último cambio antes del video: commit `a5cf3a2`, 15/01/2026; el siguiente, `a532e9e` del 23/02/2026, solo tocó `Minimal`) comparado con el actual:

| ID | En el video (17/02/2026) | Hoy | Nota |
|---|---|---|---|
| `WPFTweaksActivity` | sí | sí | |
| `WPFTweaksConsumerFeatures` | sí | sí | |
| `WPFTweaksDisableExplorerAutoDiscovery` | sí | sí | |
| `WPFTweaksWPBT` | sí | sí | |
| `WPFTweaksLocation` | sí | sí | |
| `WPFTweaksServices` | sí | sí | |
| `WPFTweaksTelemetry` | sí | sí | Hoy incluye lo que antes era `WPFTweaksPowershell7Tele` (commit `d7b0389`). |
| `WPFTweaksDiskCleanup` | sí | sí | |
| `WPFTweaksDeleteTempFiles` | sí | sí | |
| `WPFTweaksEndTaskOnTaskbar` | sí | sí | |
| `WPFTweaksRestorePoint` | sí | sí | |
| `WPFTweaksPowershell7Tele` | sí | — | Ya no existe; absorbido por `WPFTweaksTelemetry`. |
| `WPFTweaksDVR` | figuraba | — | El tweak se había borrado del catálogo el 10/02/2026 (commit `6708756`, pasó a "Remove Xbox & Gaming Components"), antes del video. En el video no tenía efecto. |
| `WPFTweaksDeliveryOptimization` | — | sí | Agregado por upstream el 03/06/2026 (commit `9f55bce`). El video no lo menciona. |

Conclusión: lo que el video aplica con "Standard" equivale al `Standard` actual **menos** `WPFTweaksDeliveryOptimization`.

## Capturas necesarias

Ninguna. Lo único que el video tilda sin nombrarlo es el preset Standard, y su contenido a esa fecha sale del historial de git (tabla anterior).

## Resultado (decisiones del usuario)

| Ítem | Decisión | En `perfil.json` |
|---|---|---|
| 12 IDs del Standard actual, 7-Zip, VC++ 2015-2022 x86/x64 | Se mantienen | Sí |
| `WPFTweaksDeliveryOptimization` | Va, aunque no estaba en el Standard del video | Sí |
| `WPFFeaturesdotnet` (fila 12) | Va | Sí |
| `WPFTweaksRazerBlock` (fila 4) | Catálogo, desmarcado | No |
| `WPFWinUtilInstallPSProfile` (fila 11) | Catálogo, desmarcado | No |
| `WPFUpdatessecurity` (fila 15) | El botón no se usa. Se reemplaza por dos tweaks nuevos en `config/tweaksextra.json`: | |
| ↳ `WPFTweaksWindowsUpdateDefer` | Diferimiento (funciones 365 días, calidad 4 días, avisar antes de instalar), sin bloquear drivers | Sí |
| ↳ `WPFTweaksWindowsUpdateNoDrivers` | Solo el bloqueo de drivers por Windows Update | No (desmarcado) |
| `WPFUpdatesdisable` (fila 16) | Seguridad (§7) | No |

`manual`: ninguno.
