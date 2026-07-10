# CONTEXT — Protocolo de uso para Claude

Este directorio es contexto persistente de trabajo.
Leer en este orden al inicio de CUALQUIER sesión sobre esta config.

## Orden de lectura obligatorio

1. `QUICK_REFERENCE.md` — Estado actual de archivos + keymaps. SIEMPRE primero.
2. `INVARIANTS.md`      — Reglas duras. Leer antes de proponer cualquier cambio.
3. `PLUGIN_REGISTRY.md` — Detalles técnicos por plugin. Leer solo cuando se trabaje un plugin específico.

## Cuándo actualizar

| Evento                          | Archivos a actualizar                     |
|---------------------------------|-------------------------------------------|
| Se escribe/modifica un archivo  | QUICK_REFERENCE.md → sección del archivo  |
| Se añade un keybind             | QUICK_REFERENCE.md → tabla de keymaps     |
| Se instala/corrige un plugin    | PLUGIN_REGISTRY.md → entrada del plugin   |
| Se descubre una regla nueva     | INVARIANTS.md → nueva entrada             |
| Se resuelve un bug              | PLUGIN_REGISTRY.md → campo `bugs`         |

## Qué NO guardar aquí

- Código fuente (ya está en los archivos de config)
- Historial de conversación
- Explicaciones largas para el usuario (eso va en `docs/`)
