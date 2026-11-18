# PROYECTO.md — Plan del fork

> Este archivo describe **qué** se construye en este fork y **con qué reglas**.
> **Cómo** se trabaja en el repo (comandos, convenciones, verificación) está en `AGENTS.md`, que viene de WinUtil y sigue vigente.
> Si algo de este archivo choca con `AGENTS.md`, se respeta `AGENTS.md`; si eso impide cumplir este plan, preguntar antes de seguir.

---

## 1. Objetivo

Herramienta de optimización de Windows para después de formatear, basada en **WinUtil** (ChrisTitusTech/winutil), que deja la PC lista **en una sola ejecución**: se aplica un perfil único de forma automática, en fases y con reinicios, sin intervención.

- Inspiración del flujo: **WinSux** (FR33THYFR33THY/WinSux), que hace todo "en un clic" con fases y reinicios.
- **Fuentes de las recomendaciones (las tres arman el perfil):**
  1. el video de Chris Titus https://youtu.be/yKydZFJRzMk;
  2. **WinSux** (FR33THYFR33THY/WinSux);
  3. **Ultimate** (FR33THYFR33THY/Ultimate).

  Todo lo que recomiendan viene **marcado por defecto** en el perfil, con una única excepción: los ítems de seguridad (§7), que quedan como opción. Cómo se adapta lo que no se puede copiar tal cual está en §6.4.

Nombre de la herramienta: `<NOMBRE>` (pendiente, ver §12).

---

## 2. Principios (no negociables)

1. **Un solo perfil.** No hay presets alternativos. El perfil (`config/perfil.json`) es lo recomendado y viene marcado; el resto del catálogo queda disponible, desmarcado.
2. **Lo del video, WinSux y Ultimate va por defecto**, salvo seguridad. Si una fuente recomienda algo de la lista de §7, ese ítem no se marca: se ofrece en la pantalla de Seguridad.
3. **Seguridad solo por elección explícita.** Ningún ítem de §7 viene marcado. Cada uno requiere confirmación.
4. **Todo reversible.** Cada cambio tiene su forma de deshacer (`UndoScript`, `OriginalValue`, `OriginalType`). Si algo no se puede deshacer, se aclara en la descripción.
5. **Punto de restauración primero.** Antes de cualquier cambio: punto de restauración + backup (`reg export`) de las claves que se van a tocar.
6. **Fuentes oficiales.** Las apps se instalan con **winget**. Nunca descargar ejecutables desde repos de terceros (WinSux y Ultimate re-hostean instaladores en sus releases: eso no se copia).
7. **Nunca dejar la PC trabada en modo seguro.** Ver §5.3.
8. **Transparencia.** El `.ps1` publicado se compila con GitHub Actions desde el código del repo, sin envoltorios en Base64, y cada release publica su SHA256.
9. **Sincronizable con WinUtil.** El código propio va en archivos nuevos; los archivos de WinUtil se tocan lo mínimo (§3).
10. **Hardware primero.** Un tweak que es para un hardware específico lleva el campo `Condicion` (§6.2) y solo se aplica si coincide con el hardware elegido o detectado (para la GPU, el selector de §5.4).
11. **Prioridad de fuentes: WinUtil > WinSux > Ultimate.** De WinSux y Ultimate se agrega solo lo que WinUtil no tiene. Si dos fuentes escriben la misma clave con valores distintos, gana la de mayor prioridad; el caso queda anotado en la tabla de conflictos (§6.5), que es informativa.

---

## 3. Base, estrategia de fork y estructura de carpetas

- Base: fork de `ChrisTitusTech/winutil` (rama `main`). Mantener `upstream` como remoto y traer cambios con regularidad.
- **No modificar `AGENTS.md`.** Este archivo se carga desde `CLAUDE.md` (línea `@PROYECTO.md`).

### 3.1 Estructura

```
PROYECTO.md                         este plan
CLAUDE.md                           @AGENTS.md + @PROYECTO.md
config/
  perfil.json                       perfil único (formato de -Config, ver §4)
  tweaksextra.json                  tweaks nuevos, mismo esquema que tweaks.json
  seguridad.json                    (etapa 7) ítems opcionales de §7
functions/
  private/Merge-WinUtilTweaksExtra.ps1  fusiona tweaksextra.json en $sync.configs.tweaks
  private/Express/*.ps1             motor de fases (estado, retoma, modo seguro, reporte)
  public/Invoke-WPFExpress*.ps1     entradas públicas del Modo Express
xaml/                               pestaña Express y pantalla de Seguridad (etapa 4)
proyecto/                           documentación del fork (NO se compila)
  README.md                         índice de esta carpeta
  video-recomendaciones.md          tabla de recomendaciones del video (etapa 1)
  winsux-ultimate.md                tabla de acciones de WinSux y Ultimate (etapa 1b)
  conflictos.md                     claves que dos fuentes escriben distinto (etapa 1b)
  fuentes/                          transcripciones y material bajado (NO se sube a git)
```

### 3.2 Reglas técnicas verificadas

- `Compile.ps1` incluye **todas** las funciones de `functions/` (recursivo) y **todos** los `config/*.json`, como `$sync.configs.<nombre-del-archivo>`. Los archivos nuevos se compilan solos.
- **Los nombres de archivo en `config/` no pueden llevar guiones ni espacios.** `config/express-perfil.json` generaría `$sync.configs.express-perfil`, que es un error de sintaxis y rompe el script compilado. Usar `perfil.json`, `tweaksextra.json`, etc.
- `pester/configs.Tests.ps1` exige que todo `config/*.json` sea JSON válido. Mantenerlo así en todo momento.
- `docs/` es el sitio web de WinUtil (Astro). La documentación propia va en `proyecto/`, no en `docs/`.
- `proyecto/fuentes/` se excluye localmente con `.git/info/exclude` (no tocar el `.gitignore` de WinUtil). Las transcripciones no se suben al repo.
- Los tweaks de `tweaksextra.json` se fusionan en `$sync.configs.tweaks` con `Merge-WinUtilTweaksExtra` (`functions/private/Merge-WinUtilTweaksExtra.ps1`). Se llama una sola vez en `scripts/main.ps1`, justo después de cargar los configs: **antes** de que `-Config`/`-Preset` validen los IDs y antes de que se generen los controles de la interfaz. Un ID que ya existe en `tweaks.json` no se pisa: se salta con un aviso en el log.
- `-Config` y `-Preset` solo aceptan IDs de selección (`WPFTweaks…`, `WPFToggle…`, `WPFFeature…`, `WPFInstall…`, `WPFAppx…`). Con `-Config`, un ID desconocido corta la ejecución (`Update-WinUtilSelections` tira "Unknown selection key"). Los botones de WinUtil (`WPFUpdatessecurity`, `WPFPanel…`, etc.) **no** pueden ir en `perfil.json`: si hace falta su efecto, se replica como tweak en `tweaksextra.json`.
- Cuando un cambio en archivos de WinUtil sea inevitable, que sea mínimo y quede listado en §11.
- En este equipo, la política de ejecución de PowerShell bloquea los scripts. Para compilar usar siempre `powershell -ExecutionPolicy Bypass -File .\Compile.ps1`, y para los tests `powershell -ExecutionPolicy Bypass -Command "..."`. Eso afecta solo a ese proceso. Nunca cambiar la política del sistema ni del usuario (`Set-ExecutionPolicy` con `-Scope LocalMachine` o `CurrentUser`).

---

## 4. Lo que ya resuelve WinUtil (reutilizar, no reescribir)

- Ejecución sin ventana: `-Config <archivo.json|url>` y `-Preset <nombre>`, vía `Invoke-WinUtilAutoRun`, que aplica en orden tweaks, toggles, features, apps (winget) y eliminación de AppX.
- **Formato de perfil:** el de `Invoke-WPFImpex`, un **array plano de IDs**: `WPFTweaks…`, `WPFToggle…`, `WPFFeature…`, `WPFInstall<clave de applications.json>` (ej. `WPFInstall7zip`), `WPFAppx…`. `config/perfil.json` usa este formato tal cual, así ya funciona hoy con `-Config config\perfil.json`.
- Esquema de tweaks: `Content`, `Description`, `category`, `panel`, `link`, `registry[]` (`Path`, `Name`, `Value`, `Type`, `OriginalValue`), `service[]` (`Name`, `StartupType`, `OriginalType`), `InvokeScript`, `UndoScript`, `Type` (toggle, combo).
- La categoría `z__Advanced Tweaks - CAUTION` de `tweaks.json` es donde Chris Titus deja lo delicado.
- Catálogo de apps (`config/applications.json`), que ya incluye 7-Zip, DDU, Helium, MSI Afterburner y VC++ 2015-2022.
- Plantilla `tools/autounattend.xml`.
- Logs, punto de restauración (`WPFTweaksRestorePoint`) y tests en `pester/`.

---

## 5. Modo Express

### 5.1 Fases

| Fase | Contenido | ¿Reinicio? | Por defecto |
|---|---|---|---|
| 0. Preparación | Punto de restauración + `reg export` de las claves afectadas + guardar el estado inicial | No | Siempre |
| 1. Base | Apps del perfil con winget (VC++ 2005–2022 x86/x64, DirectX, 7-Zip y las que recomienden las fuentes) | No | Según perfil |
| 2. Limpieza | Edge, AppX, features | No | Según perfil |
| 3. Optimización | Tweaks y toggles del perfil (WinUtil + `tweaksextra.json`) | Sí | Según perfil |
| 4. Seguridad (opcional) | Solo los ítems marcados en §7. Si incluye Defender, se agrega un arranque en modo seguro | Solo si hace falta | **Nada marcado** |
| 5. Drivers (opcional) | DDU en modo seguro + driver de GPU desde fuente oficial | Sí | No |
| 6. Cierre | Limpieza de temporales, reporte final, reinicio | Sí | Siempre |

Las fases que no tienen nada seleccionado se saltean.

### 5.2 Motor de fases

- **Estado** en `%ProgramData%\<NOMBRE>\express-state.json`: perfil usado, fase actual, pasos completados, errores y la ruta del script.
- El motor debe ser **idempotente**: si se corta en el medio, al retomar continúa desde el último paso confirmado, sin repetir pasos ya hechos.
- **Retomar después de reiniciar:**
  - Arranque normal: tarea programada "al iniciar sesión" con privilegios más altos (preferible a `RunOnce` por la elevación). Se elimina al terminar.
  - Modo seguro: la tarea programada no corre, así que se usa `HKLM\...\RunOnce` con prefijo `*` (WinSux usa ese mecanismo; ver `stepone.ps1` como referencia, no para copiar).
  - Validar ambos mecanismos en una VM antes de darlos por buenos.
- La herramienta se copia a `%ProgramData%\<NOMBRE>\` antes del primer reinicio, para no depender de `%TEMP%` ni de la carpeta de descargas.
- **Reporte final** (`%ProgramData%\<NOMBRE>\reporte-<fecha>.md` y en pantalla): qué se aplicó, qué falló, qué quedó pendiente y cómo deshacer cada cosa.

### 5.3 Seguro de modo seguro (obligatorio)

Antes de reiniciar en modo seguro (`bcdedit /set {current} safeboot minimal`):
1. Registrar una entrada `RunOnce` con `*` cuya **primera acción** sea `bcdedit /deletevalue {current} safeboot`, así el siguiente arranque es normal pase lo que pase.
2. Cualquier error dentro del modo seguro: registrar, quitar `safeboot` y reiniciar a modo normal. Nunca quedar en un bucle.
3. Test obligatorio: simular un fallo dentro del modo seguro en la VM y confirmar que la PC vuelve sola al arranque normal.

### 5.4 Interfaz

- Pestaña "Express": el perfil precargado y marcado, lista de fases, resumen y botón "Ejecutar". El usuario puede desmarcar cosas antes de ejecutar.
- **Selector de GPU** en la pestaña Express (como el menú "5 Graphics" de Ultimate: NVIDIA, AMD, Intel). Arranca preseleccionado con la detección automática (`Win32_VideoController`) y el usuario lo puede cambiar. Los tweaks con `Condicion` de GPU (§6.2) y la fase 5 usan esa selección.
- Sin ventana: se usa la detección automática, o el parámetro `-GPU NVIDIA|AMD|Intel` si se pasa (gana sobre la detección).
- Pantalla "Seguridad" separada (§7), con advertencias claras.
- Antes de ejecutar: resumen final con todo lo que se va a hacer y la cantidad de reinicios estimada.
- Idioma: español e inglés. Se puede tomar la traducción de APBOptimizer (`config/es.json`, `config/localization.json`, licencia MIT, mantener el crédito).

---

## 6. Catálogo de tweaks y armado del perfil

### 6.1 Cómo se arma `config/perfil.json`

El perfil es la suma de las tres fuentes de §1, todo marcado salvo seguridad (§7).

1. **Punto de partida:** el preset `Standard` de Chris Titus (de `config/preset.json`) + 7-Zip y VC++ 2015-2022.
2. **Video (etapa 1, hecha):** `proyecto/video-recomendaciones.md`.
3. **WinSux y Ultimate (etapa 1b):** `proyecto/winsux-ultimate.md`, una fila por cada acción de `winsux.ps1`, `stepone.ps1`, `steptwo.ps1`, `reg.reg` y cada script de Ultimate. Columnas: fuente, qué hace, destino, ID de WinUtil si existe, condición de hardware y conflictos.
   - Incluye **toda** la carpeta `5 Graphics` de Ultimate (driver clean e install, NVIDIA/AMD/Intel Settings, HDCP, P0 State, MSI Mode, DirectX, C++, HAGS), indicando para cada fila si va a la **fase 5** (drivers) o es un **tweak condicionado por GPU**.
   - Los ajustes de energía de gráficos de `steptwo.ps1` (Intel, AMD, gráficos híbridos) también llevan `Condicion`.

Cada recomendación se clasifica en uno de estos destinos:

| Destino | Qué es | ¿Va en `perfil.json`? |
|---|---|---|
| `existente` | Ya existe en WinUtil (tweak, toggle, feature, app, AppX) | **Sí**, con su ID |
| `nuevo` | No existe; se crea en `tweaksextra.json` (o como app en el catálogo) | **Sí**, cuando esté implementado |
| `seguridad` | Está en la lista de §7 | **No**: va a la pantalla de Seguridad |
| `manual` | No se puede automatizar (BIOS, panel de la GPU, hardware) | No: va a la checklist del reporte final |
| `fuera` | Excluido por §6.4 | No |
| `no aplica` | Opinión, contexto o algo que no es una acción (solo en la tabla del video) | No |

4. Lo que **ninguna** de las tres fuentes recomienda queda en el catálogo, desmarcado.
5. Si una fuente recomienda algo que en WinUtil está en `z__Advanced Tweaks - CAUTION` y **no** es de §7, igual va en el perfil (decisión del usuario: las fuentes mandan), pero su descripción debe decir claramente qué hace.
6. Un ítem con `Condicion` (§6.2) va en el perfil marcado; el motor lo saltea si no coincide con el hardware.
7. Un ítem de WinSux o Ultimate que WinUtil ya cubre (misma clave) no se agrega: queda el de WinUtil (§6.5).
8. Decisiones de la revisión del video (etapa 1): `WPFTweaksDeliveryOptimization` y `WPFFeaturesdotnet` van en el perfil; `WPFTweaksRazerBlock` y `WPFWinUtilInstallPSProfile` quedan desmarcados; el botón `WPFUpdatessecurity` no se usa: su diferimiento se replica en `WPFTweaksWindowsUpdateDefer` (marcado) y su bloqueo de drivers en `WPFTweaksWindowsUpdateNoDrivers` (desmarcado), ambos en `tweaksextra.json`.

### 6.2 Campos propios en los tweaks nuevos

En `tweaksextra.json`, además del esquema de WinUtil:
- `Origen`: de dónde sale (ej. `"Video Chris Titus 12:34"`, `"WinSux reg.reg"`, `"Ultimate 6/26"`).
- `Riesgo`: `bajo`, `medio` o `alto`, como información en la interfaz (no decide si va al perfil).
- `Condicion` (opcional): el hardware que el tweak necesita, como `"<tipo>:<valor>"`. Ejemplos: `"GPU:NVIDIA"`, `"GPU:AMD"`, `"GPU:Intel"`, `"CPU:Intel"`, `"CPU:AMD"`, `"Equipo:Notebook"`, `"Equipo:Escritorio"`. La lista de valores se cierra en la etapa 1b. Para `GPU:` vale la selección del selector de GPU (§5.4: detección automática o `-GPU`); el resto lo detecta el motor en la fase 0. El tweak se aplica solo si coincide; si no, se saltea y se informa en el reporte. Un tweak sin `Condicion` se aplica en cualquier equipo.

### 6.3 Fuentes y su contenido

1. **WinSux** (`winsux.ps1`, `stepone.ps1`, `steptwo.ps1` y `reg.reg`, unas 1.500 líneas): separar en tweaks individuales agrupados por tema, con descripción en español e inglés y `OriginalValue`. Lo que WinUtil ya cubre se marca como `existente` (comparar por clave de registro, no por nombre).
2. **Ultimate** (FR33THYFR33THY/Ultimate), cada script. Algunos ítems ya identificados:
   - ahorro de energía y "wake" en el Administrador de dispositivos (6/25) y en la placa de red (6/26);
   - sonido (6/23); Notepad (6/21); Panel de control (6/22);
   - HAGS (5/14); escalado (6/12);
   - write cache buffer flushing (6/28, con advertencia sobre cortes de luz);
   - MSI Mode (5/10), Timer Resolution (6/30; WinSux trae un servicio en `settimerresolutionservice.cs`), P0 State (5/9), ULPS (8/14), prioridades (8/10), memory compression (3/2), NVMe (8/19).
3. **APBOptimizer** (OptiJuegos/APBOptimizer, MIT): **no** es fuente del perfil. Aporta modo guiado, traducción y tweaks extra, que entran al catálogo desmarcados. Revisar antes de traer.

Lo de WinSux y Ultimate que WinUtil no tiene entra al perfil marcado, salvo lo que sea `seguridad`, `manual` o `fuera`.

### 6.4 Cómo se integra lo que no se puede copiar tal cual

| En la fuente | Cómo entra acá |
|---|---|
| Apps descargadas desde los releases de WinSux/Ultimate | Se instalan con **winget** desde la fuente oficial. Si no están en winget, la fila queda `manual`. |
| Bloqueo de Windows Update apuntando `WUServer` a un dominio externo (Ultimate 2/5) | Opción de **Seguridad** (§7), apuntando a `127.0.0.1`. |
| DDU automático sobre todos los drivers (audio, Intel, Realtek), como hace WinSux | **Solo GPU**, en la fase 5 y con elección explícita. |

Excluido (destino `fuera`, no se implementa):
- Política de ejecución `Unrestricted` global y abrir `.ps1` con doble clic (Ultimate `AllowScripts.cmd` e `IWR.ps1`).
- Activación con MAS (Ultimate 3/4).

### 6.5 Conflictos entre fuentes

Prioridad: **WinUtil (incluye lo del video) > WinSux > Ultimate.**

- De WinSux y Ultimate se agrega solo lo que WinUtil no tiene. Si escriben el mismo valor que WinUtil, no se duplica: queda el tweak de WinUtil.
- Si dos fuentes escriben la misma clave de registro, servicio o configuración con valores distintos, por defecto gana la de mayor prioridad (si WinUtil la toca, queda el valor de WinUtil).
- Cada uno de esos casos se anota en `proyecto/conflictos.md` (se crea en la etapa 1b) con la clave, el valor de cada fuente, qué hace cada uno y cuál ganó. La tabla es **informativa**: el usuario puede cambiar casos puntuales, y ese cambio queda anotado en la misma tabla.

---

## 7. Seguridad (siempre opcional)

Esta es la **única excepción** a "lo de las fuentes va por defecto". Ningún ítem de esta lista viene marcado, aunque una fuente lo recomiende; en ese caso se indica en la pantalla (ej. "recomendado por WinSux") pero la casilla arranca vacía.

- Vive en un archivo **separado** del script principal, para que Defender no marque la herramienta entera por contener código que lo desactiva.
- Si se distribuye aparte, se descarga desde el release **de la misma versión** y se verifica contra un SHA256 fijado en el script principal antes de ejecutarlo. Si el hash no coincide, se aborta.
- Pantalla propia. Cada ítem con: qué protege, qué se gana al desactivarlo, si requiere modo seguro, y su forma de deshacer.

| Ítem | Notas |
|---|---|
| Defender: tiempo real, nube, antimanipulación | Requiere modo seguro y ejecución como TrustedInstaller (técnica de WinSux `stepone.ps1`, `Run-Trusted`). Restaurar `binPath` siempre, incluso si falla. |
| SmartScreen y protección contra phishing | |
| Bloqueo de apps potencialmente no deseadas (PUA) | |
| Integridad de memoria (HVCI) y VBS | WinUtil no lo tiene. APBOptimizer sí (`WPFTweaksDisableMemoryIntegrity`, MIT): revisar y adaptar. |
| Protección de LSA | |
| Lista de bloqueo de drivers vulnerables | |
| UAC | |
| Mitigaciones de CPU (Spectre/Meltdown) | WinUtil no lo tiene. APBOptimizer sí (`WPFTweaksDisableCPUMitigations`, MIT): revisar y adaptar. |
| Desactivar o pausar Windows Update a largo plazo | Deja de recibir parches de seguridad. WinUtil tiene los botones `WPFUpdatesdisable` (desactivar) y `WPFUpdatesdefault` (volver al estado original). El bloqueo de Ultimate (2/5) entra acá apuntando `WUServer` a `127.0.0.1`, nunca a un dominio externo. El diferimiento sin riesgo (`WPFTweaksWindowsUpdateDefer`, en `tweaksextra.json`) no es de esta lista y va en el perfil. |
| Firewall | |
| BitLocker | WinUtil ya tiene `WPFTweaksDisableBitLocker`; reutilizar. Va acá aunque WinUtil lo tenga en "Essential Tweaks". |

Nunca incluir, ni siquiera como opción: DEP (`nx AlwaysOff`), bypass de firma de drivers con Secure Boot, ni la advertencia de archivos descargados.

---

## 8. Fase 0 externa: `autounattend.xml`

Opcional pero recomendado: un generador (o una plantilla documentada) de `autounattend.xml` para el USB de instalación que:
- cree una cuenta local y omita la configuración inicial y las pantallas de privacidad;
- evite las apps promocionadas;
- deje la herramienta programada para el primer inicio de sesión con el perfil.

Partir de `tools/autounattend.xml` de WinUtil.

---

## 9. Pruebas

- VM (Hyper-V o VirtualBox) con snapshots: Windows 11 actual y Windows 10 22H2.
- Para cada tweak nuevo: aplicar, verificar, deshacer y verificar que volvió al valor original.
- Para el motor:
  - ejecución completa con `perfil.json`;
  - corte de energía simulado en cada fase (apagar la VM) y retoma;
  - fallo dentro del modo seguro (§5.3);
  - perfil vacío;
  - perfil solo con apps.
- Tests en `pester/` para las funciones nuevas que no dependan de la interfaz (motor de estado, fusión de `tweaksextra.json`, lectura del perfil, que todo ID de `perfil.json` exista en algún config, que ningún ID de §7 esté en `perfil.json`, verificación de hash).
- Respetar la sección de verificación de `AGENTS.md`.

---

## 10. Publicación

- Adaptar los workflows de `.github/workflows/` (WinUtil ya compila en `compile-check.yaml` y `pre-release.yaml`) para generar el `.ps1` propio en cada release.
- Publicar el SHA256 del `.ps1` (y del módulo de seguridad) en las notas del release.
- Lanzador `.cmd` opcional que pida administrador y ejecute el `.ps1` local con `-ExecutionPolicy Bypass` **solo para ese proceso**, sin cambiar la política del sistema.
- Sin `.exe` por ahora: los envoltorios tipo PS2EXE suelen dar falsos positivos y le quitan transparencia.
- Mantener `LICENSE` de WinUtil y agregar créditos (WinUtil, APBOptimizer, FR33THY) en el README y en "Acerca de".

---

## 11. Orden de trabajo

Cada etapa termina con sus pruebas pasando y un commit propio. No avanzar a la siguiente sin confirmar con el usuario.

0. **Preparación del fork:** confirmar que compila y abre igual que upstream con los archivos de esta estructura. Agregar `proyecto/fuentes/` a `.git/info/exclude`.
1. **Video:** bajar subtítulos y descripción (ver `proyecto/video-recomendaciones.md`), completar la tabla, y actualizar `perfil.json` con los ítems `existente`. Mostrarle la tabla al usuario antes de tocar `perfil.json`. Incluye (adelantado desde la etapa 5) el punto de enganche de `tweaksextra.json` y los dos tweaks de Windows Update que reemplazan al botón `WPFUpdatessecurity`.
1b. **WinSux y Ultimate:** clonar ambos repos en `proyecto/fuentes/` y armar `proyecto/winsux-ultimate.md` (§6.1) y `proyecto/conflictos.md` (§6.5). Mostrarle la tabla al usuario antes de tocar `perfil.json`.
2. **Motor de fases** (sin interfaz): estado, retoma con tarea programada, reporte, fases 0, 1, 2 y 3 usando `Invoke-WinUtilAutoRun` con `perfil.json`. Probado en VM.
3. **Ejecución Express sin ventana:** parámetro `-Express` que usa el perfil embebido (`$sync.configs.perfil`) o uno externo, y `-GPU NVIDIA|AMD|Intel` (si falta, detección automática).
4. **Interfaz Express**, selector de GPU (§5.4) y resumen previo.
5. **Catálogo:** implementar los ítems `nuevo` de las fuentes (entran al perfil), con su `Condicion` cuando corresponda, y después los de APBOptimizer (desmarcados), por tandas temáticas.
6. **Modo seguro + seguro anti-bloqueo** (§5.3) y **fase 5 de drivers**.
7. **Seguridad** (§7): `config/seguridad.json` o módulo aparte, y su pantalla.
8. **Español** (tomado de APB) y diseño propio (logo, tema).
9. **Publicación** (§10) y `autounattend.xml` (§8).

Archivos de WinUtil modificados (mantener actualizada esta lista):
- `CLAUDE.md`: se agregó `@PROYECTO.md`.
- `scripts/main.ps1`: una llamada a `Merge-WinUtilTweaksExtra` después de cargar los configs (§3.2).

---

## 12. Decisiones

Tomadas:
- Un solo perfil. Lo que recomiendan el video de Chris Titus, WinSux y Ultimate va marcado por defecto.
- Seguridad (§7) siempre opcional y desmarcada.
- Tweaks de un hardware específico: campo `Condicion`, se aplican solo si coincide el hardware. La GPU sale de un selector preseleccionado con la detección (o `-GPU` sin ventana).
- Prioridad de fuentes WinUtil > WinSux > Ultimate; la tabla de conflictos es informativa (§6.5).
- Revisión del video: ver §6.1, punto 8.

Pendientes:
- Nombre de la herramienta.
- Hardware de referencia (GPU, CPU, notebook o escritorio), para la fase de drivers.
- Navegador en la fase 1, si ninguna fuente recomienda uno.
- Equipos con dos GPU (gráficos híbridos, ej. Intel + NVIDIA): si el selector admite más de una GPU o una sola, y cómo se condicionan los ajustes híbridos de `steptwo.ps1`.
- Si el módulo de seguridad se distribuye dentro del release o como descarga aparte.

---

## 13. Referencias

- Video base: https://youtu.be/yKydZFJRzMk (Chris Titus)
- WinUtil: https://github.com/ChrisTitusTech/winutil (MIT)
- APBOptimizer: https://github.com/OptiJuegos/APBOptimizer (fork de WinUtil, MIT). Análisis previo: el `.ps1` publicado en `OptiJuegos/host` coincide con el código fuente; no se encontró nada malicioso.
- Ultimate: https://github.com/FR33THYFR33THY/Ultimate (MIT)
- WinSux: https://github.com/FR33THYFR33THY/WinSux (MIT)
