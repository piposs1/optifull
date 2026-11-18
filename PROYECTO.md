# PROYECTO.md — Plan del fork

> Este archivo describe **qué** se construye en este fork y **con qué reglas**.
> **Cómo** se trabaja en el repo (comandos, convenciones, verificación) está en `AGENTS.md`, que viene de WinUtil y sigue vigente.
> Si algo de este archivo choca con `AGENTS.md`, se respeta `AGENTS.md`; si eso impide cumplir este plan, preguntar antes de seguir.

---

## 1. Objetivo

Herramienta de optimización de Windows para después de formatear, basada en **WinUtil** (ChrisTitusTech/winutil), que deja la PC lista **en una sola ejecución**: se aplica un perfil único de forma automática, en fases y con reinicios, sin intervención.

- Inspiración del flujo: **WinSux** (FR33THYFR33THY/WinSux), que hace todo "en un clic" con fases y reinicios. Del flujo se toma la idea; de su contenido, solo lo que diga este archivo.
- **Fuente de las recomendaciones:** el video de Chris Titus https://youtu.be/yKydZFJRzMk. Todo lo que el video recomienda viene **marcado por defecto** en el perfil, con una única excepción: los ítems de seguridad (§7), que quedan como opción.

Nombre de la herramienta: `<NOMBRE>` (pendiente, ver §12).

---

## 2. Principios (no negociables)

1. **Un solo perfil.** No hay presets alternativos. El perfil (`config/perfil.json`) es lo recomendado y viene marcado; el resto del catálogo queda disponible, desmarcado.
2. **Lo del video va por defecto**, salvo seguridad. Si el video recomienda algo de la lista de §7, ese ítem no se marca: se ofrece en la pantalla de Seguridad.
3. **Seguridad solo por elección explícita.** Ningún ítem de §7 viene marcado. Cada uno requiere confirmación.
4. **Todo reversible.** Cada cambio tiene su forma de deshacer (`UndoScript`, `OriginalValue`, `OriginalType`). Si algo no se puede deshacer, se aclara en la descripción.
5. **Punto de restauración primero.** Antes de cualquier cambio: punto de restauración + backup (`reg export`) de las claves que se van a tocar.
6. **Fuentes oficiales.** Las apps se instalan con **winget**. Nunca descargar ejecutables desde repos de terceros (WinSux y Ultimate re-hostean instaladores en sus releases: eso no se copia).
7. **Nunca dejar la PC trabada en modo seguro.** Ver §5.3.
8. **Transparencia.** El `.ps1` publicado se compila con GitHub Actions desde el código del repo, sin envoltorios en Base64, y cada release publica su SHA256.
9. **Sincronizable con WinUtil.** El código propio va en archivos nuevos; los archivos de WinUtil se tocan lo mínimo (§3).

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
  private/Express/*.ps1             motor de fases (estado, retoma, modo seguro, reporte)
  public/Invoke-WPFExpress*.ps1     entradas públicas del Modo Express
xaml/                               pestaña Express y pantalla de Seguridad (etapa 4)
proyecto/                           documentación del fork (NO se compila)
  README.md                         índice de esta carpeta
  video-recomendaciones.md          tabla de recomendaciones del video (etapa 1)
  fuentes/                          transcripciones y material bajado (NO se sube a git)
```

### 3.2 Reglas técnicas verificadas

- `Compile.ps1` incluye **todas** las funciones de `functions/` (recursivo) y **todos** los `config/*.json`, como `$sync.configs.<nombre-del-archivo>`. Los archivos nuevos se compilan solos.
- **Los nombres de archivo en `config/` no pueden llevar guiones ni espacios.** `config/express-perfil.json` generaría `$sync.configs.express-perfil`, que es un error de sintaxis y rompe el script compilado. Usar `perfil.json`, `tweaksextra.json`, etc.
- `pester/configs.Tests.ps1` exige que todo `config/*.json` sea JSON válido. Mantenerlo así en todo momento.
- `docs/` es el sitio web de WinUtil (Astro). La documentación propia va en `proyecto/`, no en `docs/`.
- `proyecto/fuentes/` se excluye localmente con `.git/info/exclude` (no tocar el `.gitignore` de WinUtil). Las transcripciones no se suben al repo.
- Los tweaks de `tweaksextra.json` necesitan un único punto de enganche que los fusione en `$sync.configs.tweaks` al iniciar, **antes** de que se generen los controles de la interfaz. Debe ser un cambio chico y comentado.
- Cuando un cambio en archivos de WinUtil sea inevitable, que sea mínimo y quede listado en §11.

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
| 1. Base | Apps del perfil con winget (VC++ 2005–2022 x86/x64, DirectX, 7-Zip y las que recomiende el video) | No | Según perfil |
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
- Pantalla "Seguridad" separada (§7), con advertencias claras.
- Antes de ejecutar: resumen final con todo lo que se va a hacer y la cantidad de reinicios estimada.
- Idioma: español e inglés. Se puede tomar la traducción de APBOptimizer (`config/es.json`, `config/localization.json`, licencia MIT, mantener el crédito).

---

## 6. Catálogo de tweaks y armado del perfil

### 6.1 Cómo se arma `config/perfil.json`

1. **Punto de partida (ya cargado):** el preset `Standard` de Chris Titus (de `config/preset.json`) + 7-Zip y VC++ 2015-2022. Es provisorio hasta procesar el video.
2. **Video (etapa 1):** cada recomendación del video se registra en `proyecto/video-recomendaciones.md` y se clasifica en uno de estos destinos:

| Destino | Qué es | ¿Va en `perfil.json`? |
|---|---|---|
| `existente` | Ya existe en WinUtil (tweak, toggle, feature, app, AppX) | **Sí**, con su ID |
| `nuevo` | No existe; se crea en `tweaksextra.json` (o como app en el catálogo) | **Sí**, cuando esté implementado |
| `seguridad` | Está en la lista de §7 | **No**: va a la pantalla de Seguridad |
| `manual` | No se puede automatizar (BIOS, panel de la GPU, hardware) | No: va a la checklist del reporte final |
| `no aplica` | Opinión, contexto o algo que no es una acción | No |

3. Lo que el video **no** menciona queda en el catálogo, desmarcado.
4. Si el video recomienda algo que en WinUtil está en `z__Advanced Tweaks - CAUTION` y **no** es de §7, igual va en el perfil (decisión del usuario: lo del video manda), pero su descripción debe decir claramente qué hace.

### 6.2 Campos propios en los tweaks nuevos

En `tweaksextra.json`, además del esquema de WinUtil:
- `Origen`: de dónde sale (ej. `"Video Chris Titus 12:34"`, `"WinSux reg.reg"`, `"Ultimate 6/26"`).
- `Riesgo`: `bajo`, `medio` o `alto`, como información en la interfaz (no decide si va al perfil).

### 6.3 Otras fuentes (complementarias, sin marcar por defecto)

1. **WinSux** (`WinSux/reg.reg`, unas 1.500 líneas, y las secciones de `steptwo.ps1`): separar en tweaks individuales agrupados por tema, con descripción en español e inglés y `OriginalValue`. Descartar lo que WinUtil ya cubre (comparar por clave de registro, no por nombre).
2. **Ultimate** (FR33THYFR33THY/Ultimate):
   - ahorro de energía y "wake" en el Administrador de dispositivos (6/25) y en la placa de red (6/26);
   - sonido (6/23); Notepad (6/21); Panel de control (6/22);
   - HAGS (5/14); escalado (6/12);
   - write cache buffer flushing (6/28, con advertencia sobre cortes de luz);
   - MSI Mode (5/10), Timer Resolution (6/30; WinSux trae un servicio en `settimerresolutionservice.cs`), P0 State (5/9), ULPS (8/14), prioridades (8/10), memory compression (3/2), NVMe (8/19).
3. **APBOptimizer** (OptiJuegos/APBOptimizer, MIT): modo guiado, traducción y tweaks extra. Revisar antes de traer.

Estos ítems entran al catálogo desmarcados. Solo pasan al perfil si el video los recomienda.

### 6.4 Excluido (no implementar)

- Instaladores descargados desde releases de terceros (WinSux/Ultimate).
- Política de ejecución `Unrestricted` global y abrir `.ps1` con doble clic (Ultimate `AllowScripts.cmd` e `IWR.ps1`).
- Bloqueo de Windows Update apuntando `WUServer` a un dominio externo (Ultimate 2/5). Si hace falta, usar `127.0.0.1`.
- Activación con MAS (Ultimate 3/4).
- DDU automático sobre **todos** los drivers (audio, Intel, Realtek) como hace WinSux. En la fase 5, solo GPU y con elección explícita.

---

## 7. Seguridad (siempre opcional)

Esta es la **única excepción** a "lo del video va por defecto". Ningún ítem de esta lista viene marcado, aunque el video lo recomiende; en ese caso se indica en la pantalla ("recomendado en el video") pero la casilla arranca vacía.

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
| Desactivar o pausar Windows Update a largo plazo | Deja de recibir parches de seguridad. WinUtil tiene los botones `WPFUpdatesdisable` (desactivar), `WPFUpdatessecurity` (solo seguridad, sin riesgo: puede ir en el perfil) y `WPFUpdatesdefault` (volver al estado original). |
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
1. **Video:** bajar subtítulos y descripción (ver `proyecto/video-recomendaciones.md`), completar la tabla, y actualizar `perfil.json` con los ítems `existente`. Mostrarle la tabla al usuario antes de tocar `perfil.json`.
2. **Motor de fases** (sin interfaz): estado, retoma con tarea programada, reporte, fases 0, 1, 2 y 3 usando `Invoke-WinUtilAutoRun` con `perfil.json`. Probado en VM.
3. **Ejecución Express sin ventana:** parámetro `-Express` que usa el perfil embebido (`$sync.configs.perfil`) o uno externo.
4. **Interfaz Express** y resumen previo.
5. **Catálogo:** punto de enganche de `tweaksextra.json`; implementar los ítems `nuevo` del video (estos entran al perfil) y después los de §6.3 (desmarcados), por tandas temáticas.
6. **Modo seguro + seguro anti-bloqueo** (§5.3) y **fase 5 de drivers**.
7. **Seguridad** (§7): `config/seguridad.json` o módulo aparte, y su pantalla.
8. **Español** (tomado de APB) y diseño propio (logo, tema).
9. **Publicación** (§10) y `autounattend.xml` (§8).

Archivos de WinUtil modificados (mantener actualizada esta lista):
- `CLAUDE.md`: se agregó `@PROYECTO.md`.

---

## 12. Decisiones

Tomadas:
- Un solo perfil. Lo que recomienda el video de Chris Titus va marcado por defecto.
- Seguridad (§7) siempre opcional y desmarcada.

Pendientes:
- Nombre de la herramienta.
- Hardware de referencia (GPU, CPU, notebook o escritorio), para la fase de drivers.
- Navegador en la fase 1, si el video no recomienda uno.
- Si el módulo de seguridad se distribuye dentro del release o como descarga aparte.

---

## 13. Referencias

- Video base: https://youtu.be/yKydZFJRzMk (Chris Titus)
- WinUtil: https://github.com/ChrisTitusTech/winutil (MIT)
- APBOptimizer: https://github.com/OptiJuegos/APBOptimizer (fork de WinUtil, MIT). Análisis previo: el `.ps1` publicado en `OptiJuegos/host` coincide con el código fuente; no se encontró nada malicioso.
- Ultimate: https://github.com/FR33THYFR33THY/Ultimate (MIT)
- WinSux: https://github.com/FR33THYFR33THY/WinSux (MIT)
