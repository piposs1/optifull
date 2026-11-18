# Recomendaciones del video

Video: https://youtu.be/yKydZFJRzMk (Chris Titus)
Regla (PROYECTO.md §6.1): todo lo que el video recomienda va a `config/perfil.json`, **salvo** los ítems de seguridad de PROYECTO.md §7, que quedan como opción desmarcada.

Estado: **pendiente** (etapa 1 de PROYECTO.md §11).

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

| # | Minuto | Recomendación | Destino | ID | Notas |
|---|---|---|---|---|---|
| 1 | | | | | |

## Capturas necesarias

| Minuto | Qué hace en pantalla |
|---|---|
| | |

## Perfil provisorio (antes del video)

`config/perfil.json` arranca con el preset `Standard` de WinUtil más 7-Zip y Visual C++ 2015-2022 (x86 y x64). Se reemplaza o completa con el resultado de esta tabla.
