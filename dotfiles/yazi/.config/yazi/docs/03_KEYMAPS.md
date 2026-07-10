# Módulo 3 — Interacción (Keymaps)

---

## 3.1 Arquitectura del Sistema de Keymaps

```
keymap.toml
├── [mgr]           ← File manager (Yazi 26.x: "mgr", NO "manager")
│   └── prepend_keymap = [...]   ← prioridad sobre defaults
├── [input]         ← Prompt de comandos
│   └── prepend_keymap = [...]
└── [select]        ← Multi-item picker
    └── prepend_keymap = [...]
```

**Invariante I-00:** En Yazi 26.x el contexto del manager cambió de `[manager]` a `[mgr]`. Una sección `[manager]` se parsea sin error pero sus keybinds nunca cargan — fallo silencioso.

**Invariante I-07:** Usar siempre `prepend_keymap`. `append_keymap` puede ser anulado por un default con la misma tecla.

---

## 3.2 Tabla Completa — Contexto [mgr]

### Navegación

| Tecla(s) | Comando | Fuente | Nota |
|----------|---------|--------|------|
| `h` | `leave` | custom | Ir al directorio padre |
| `l` / `→` / `Enter` | `plugin bypass smart-enter` | custom | Smart enter (dirs de hijo único) |
| `H` | `back` | custom | Historial: atrás |
| `L` | `forward` | custom | Historial: adelante |
| `j` / `↓` | `arrow 1` | default | Cursor abajo |
| `k` / `↑` | `arrow -1` | default | Cursor arriba |
| `g,g` | `arrow -99999999` | default | Ir al inicio |
| `G` | `arrow 99999999` | default | Ir al final |
| `<C-d>` | `arrow 50%` | default | Página abajo |
| `<C-u>` | `arrow -50%` | default | Página arriba |
| `1`–`9` | `plugin relative-motions N` | custom | Movimiento relativo (ej: 3j = bajar 3) |

### Ordenación

| Tecla(s) | Comando | Resultado |
|----------|---------|-----------|
| `s,n` | `sort natural --dir-first` | Natural (A1 < A2 < A10) |
| `s,a` | `sort alphabetical --dir-first` | Alfabético estricto |
| `s,m` | `sort modified --dir-first --reverse` | Más reciente primero |
| `s,s` | `sort size --dir-first --reverse` | Más grande primero |

### Tabs

| Tecla | Comando | Acción |
|-------|---------|--------|
| `T` | `tab_create --current` | Nueva pestaña en el dir actual |
| `X` | `tab_close 0` | Cerrar pestaña actual |
| `<Tab>` | `tab_switch 1 --relative` | Siguiente pestaña |
| `<S-Tab>` | `tab_switch -1 --relative` | Pestaña anterior |

### Operaciones de Archivos

| Tecla | Comando | Acción |
|-------|---------|--------|
| `Space` | `select` | Toggle selección |
| `y` | `yank` + `plugin clipboard` | Copiar + clipboard del sistema |
| `<C-p>` | `plugin clipboard -- --action=paste` | Pegar desde clipboard del sistema |
| `x` | `yank --cut` | Cortar |
| `p` | `paste` | Pegar |
| `d` | `remove` | Mover a papelera (trash nativo) |
| `a` | `create` | Crear archivo/directorio |
| `r` | `rename` | Renombrar |
| `C` | `plugin ouch` | Comprimir selección con ouch |

### Búsqueda y Filtro

| Tecla | Comando | Acción |
|-------|---------|--------|
| `f` | `filter` | Filtro inline (en directorio actual) |
| `/` | `find` | Búsqueda incremental |
| `z` | `jump` | Jump zoxide/fzf |
| `f,g` | `plugin fg` | Buscar contenido de archivos (fzf + rg) |
| `f,G` | `plugin fg -- rg` | Buscar contenido (ripgrep exacto) |
| `f,f` | `plugin fg -- fzf` | Buscar nombre de archivo (fzf) |

### Miscelánea

| Tecla | Comando | Acción |
|-------|---------|--------|
| `.` | `hidden toggle` | Mostrar/ocultar archivos ocultos |
| `!` | `shell --block --confirm` | Prompt de shell |
| `~` | `help` | Ayuda / lista de keybinds |
| `<C-s>` | `plugin what-size` | Calcular tamaño de selección o cwd |
| `I` | `plugin mediainfo -- toggle-metadata` | Toggle thumbnail/metadata |

### Plugins de Sistema

| Tecla(s) | Plugin | Acción |
|----------|--------|--------|
| `M,m` | gvfs | Montar dispositivo GVFS y saltar |
| `M,u` | gvfs | Desmontar y expulsar |
| `M,U` | gvfs | Forzar expulsión |
| `M,a` | gvfs | Añadir URI de montaje |
| `M,e` | gvfs | Editar URI de montaje |
| `M,r` | gvfs | Eliminar URI de montaje |
| `g,m` | gvfs | Saltar a dispositivo montado |
| `` `,` `` | gvfs | Volver al directorio anterior |
| `M,M` | mount | Gestor de discos locales (udisks2) |
| `g,i` | lazygit | Abrir lazygit en el dir actual |

### Papelera (recycle-bin)

| Tecla(s) | Acción |
|----------|--------|
| `R,b` | Menú principal |
| `R,o` | Abrir papelera |
| `R,r` | Restaurar archivo |
| `R,d` | Eliminar de papelera |
| `R,e` | Vaciar papelera |

---

## 3.3 Contexto [input]

| Tecla | Acción |
|-------|--------|
| `<C-c>` | Cancelar / cerrar |
| `<Esc>` | Escape |
| `<C-u>` | Borrar hasta el inicio de línea |
| `<C-k>` | Borrar hasta el final de línea |

---

## 3.4 Contexto [select]

| Tecla | Acción |
|-------|--------|
| `<Esc>` | Cancelar |
| `q` | Cancelar |

---

## 3.5 Lógica de Custom Binds

### bypass — Smart Enter

```toml
{ on = "l",       run = "plugin bypass smart-enter" }
{ on = "<Right>", run = "plugin bypass smart-enter" }
{ on = "<Enter>", run = "plugin bypass smart-enter" }
```

`smart-enter` distingue:
- **Directorio con un solo hijo** → entra directamente sin mostrar el directorio intermedio
- **Directorio con múltiples hijos** → comportamiento normal de `enter`
- **Archivo** → abre con el opener configurado

### relative-motions — Prefijos numéricos

```toml
{ on = "1", run = "plugin relative-motions 1" }
...
{ on = "9", run = "plugin relative-motions 9" }
```

El dígito actúa como prefijo. Después de pulsar `3`, el siguiente `j`/`k` mueve 3 posiciones. El status line muestra el motion activo.

**Invariante I-00b:** La sintaxis correcta es `plugin relative-motions 1` (espacio directo), **no** `plugin relative-motions --args=1`.

### clipboard — Yank extendido

```toml
{ on = "y", run = ["yank", "plugin clipboard -- --action=copy --notify-unknown-display-server"] }
```

`y` ejecuta dos comandos en secuencia:
1. `yank` → copia rutas al registro interno de Yazi
2. `plugin clipboard` → copia las mismas rutas como `text/uri-list` al clipboard de Wayland

**Verificar clipboard:** `wl-paste -t text/uri-list` (no `wl-paste` a secas — el MIME type es URI list, no texto plano).

---

## 3.6 Conflictos Conocidos y Resoluciones

| Conflicto | Causa | Resolución |
|-----------|-------|------------|
| `M,M` vs `M,m` | gvfs usa `M,m/u/U/a/e/r`; mount necesita tecla propia | `M,M` (doble mayúscula) — no colisiona |
| `s` (sort prefix) vs `s` default | Yazi default usa `s` para buscar | Sobreescrito por `prepend_keymap` — sort gana |
| `.` (hidden) vs `.` default | Yazi default no tenía `.` | Sin conflicto |
| `1`–`9` vs números en default | Yazi 26.x no usa números como binds por defecto | Sin conflicto |
| `f` (filter) vs `f,g/G/f` (fg plugin) | `f` solo no conflicta con `f,*` chords en Yazi | Sin conflicto — Yazi distingue single vs chord |

### Wayland / Kitty — Clipboard

El plugin `clipboard` de XYenon usa `wl-copy` (wl-clipboard). En Hyprland/Wayland esto funciona directamente. No requiere `xclip` ni `xsel`. Si `wl-copy` no está disponible, el plugin notifica vía `--notify-unknown-display-server`.

```bash
# Verificar disponibilidad
which wl-copy wl-paste
```
