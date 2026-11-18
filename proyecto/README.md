# proyecto/

Documentación propia del fork. Nada de esta carpeta se compila dentro del script.

| Archivo | Para qué |
|---|---|
| `../PROYECTO.md` | Plan completo: objetivos, reglas, arquitectura y orden de trabajo |
| `video-recomendaciones.md` | Recomendaciones del video de Chris Titus y a dónde va cada una |
| `fuentes/` | Material descargado (subtítulos, descripción, capturas). **No se sube a git** |

Para que `fuentes/` no se suba, agregarla a la exclusión local del repo (no toca el `.gitignore` de WinUtil):

```powershell
Add-Content .git\info\exclude "proyecto/fuentes/"
```
