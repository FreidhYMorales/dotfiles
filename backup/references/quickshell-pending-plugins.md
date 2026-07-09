# Quickshell — Plugins propios pendientes

Estado: **PENDIENTE DE IMPLEMENTACIÓN**

El lock module (y potencialmente otros módulos futuros) usa tipos de Caelestia que dependen de plugins C++ compilados. Por ahora se usan **stubs QML** que replican la API pero no la visual exacta. Más adelante se implementarán plugins propios en C++ o Rust.

---

## Plugins a implementar

### 1. M3Shapes — `MaterialShape`

**Módulo stub actual:** `backup/quickshell/M3Shapes/`  
**Prioridad:** Alta (impacta visual del lock screen — avatar, resource cards, input field)

**Qué hace en Caelestia:**
- Renderiza formas vectoriales custom con `QPainterPath`: Pentagon, Arrow, ClamShell, Gem, Slanted, Arch, Fan, SemiCircle, Triangle, Diamond, Sunny, VerySunny, Cookie4Sided, Ghostish, SoftBurst, Circle
- Tiene animaciones morph entre shapes
- Expone `pathBounds()` y `pointAtAngle(deg)` para posicionar elementos sobre las formas
- Usa `layer.enabled + ShaderEffect` para clip contra el shape

**Stub QML actual:**
- Siempre renderiza como `Rectangle` con radius
- Expone la misma API de enums (`MaterialShape.Pentagon` = 2, etc.) vía QML `enum`
- `pathBounds()` y `pointAtAngle()` son stubs funcionales con geometría circular

**Para implementar en C++:**
```
- QQuickItem subclass con Q_PROPERTY shape (Q_ENUM)
- Sobreescribir updatePaintNode() con QSGGeometryNode + QPainterPath
- Exponer pathBounds() y pointAtAngle() como Q_INVOKABLE
- Plugin CMake con QML_ELEMENT
- Módulo: M3Shapes, tipo: MaterialShape
```

**Para implementar en Rust:**
- Usar `qml-rs` o el binding de Quickshell
- Misma API, lógica QPainterPath en rust-skia o lyon

---

### 2. Caelestia.Config — `Tokens`

**Módulo stub actual:** `backup/quickshell/Caelestia/Config/`  
**Prioridad:** Media (impacta spacing/typography — actualmente hardcodeado en stub)

**Qué hace en Caelestia:**
- Singleton que provee TODO el sistema de design tokens: fonts, spacing, border-radius, icon sizes
- Lee de un archivo de configuración de Caelestia, no es un singleton estático
- Permite temas/tokens intercambiables en runtime

**Stub QML actual:**
- Singleton con valores hardcodeados razonables
- No es configurable en runtime

**Implementación futura:**
- Reemplazar el stub por un sistema propio de tokens leído desde `~/.config/quickshell/tokens.json` (o similar)
- No necesariamente un plugin C++ — puede ser un singleton QML con `FileView`
- Integrar con el pipeline matugen → colors.json

---

### 3. Caelestia.Config — `GlobalConfig` / `Config`

**Módulo stub actual:** `backup/quickshell/Caelestia/Config/`  
**Prioridad:** Baja (solo afecta config de lock: hideNotifs, paths de imágenes)

**Stub QML actual:**
- Singleton con valores hardcodeados: `lock.hideNotifs = false`, `paths.lockNoNotifsPic = ""`
- La imagen de "sin notificaciones" no se muestra

**Implementación futura:**
- Sistema de config propio con `FileView` + JSON (ya planeado en quickshell-vision.md)
- Mapear las keys de config al formato propio del proyecto

---

### 4. Caelestia.Services — `Cpu`, `Memory`, `Storage`

**Módulo stub actual:** `backup/quickshell/Caelestia/Services/`  
**Prioridad:** Baja (el stub QML con `/proc` funciona bien)

**Stub QML actual:**
- Leen de `/proc/stat`, `/proc/meminfo`, `df /` vía `Process`
- Exponen `percentage` (0.0–1.0) igual que los singletons C++ de Caelestia
- Funcionalmente equivalentes — no hay ventaja real en portar a C++

---

## Componentes QML creados como stubs (no necesitan plugin C++)

Estos son replicables perfectamente en QML puro y **no requieren plugins**:

| Componente | Módulo | Estado |
|---|---|---|
| `ButtonRow` | `Caelestia.Components` | stub QML ✅ |
| `StyledClippingRect` | `Caelestia.Components` | stub QML ✅ |
| `StyledText` | `qs.components` | implementación QML ✅ |
| `MaterialIcon` | `qs.components` | implementación QML ✅ |
| `AnimLoader` | `qs.components` | implementación QML ✅ |
| `StateLayer` | `qs.components` | stub QML ✅ |
| `WavyTopRect` | `qs.components.widgets` | Canvas QML ✅ |
| `FadeImage` | `qs.components.images` | QML ✅ |
| `CachingImage` | `qs.components.images` | QML ✅ |

---

## Decisión técnica: C++ vs Rust

Para **M3Shapes** (el único plugin que vale la pena implementar):

**C++ (recomendado para empezar):**
- Plugin Qt estándar: `QQuickItem` + `QPainterPath` + `QML_ELEMENT`
- CMake con `qt_add_qml_module`
- Documentación oficial de Qt: "Writing QML Extensions with C++"
- Path: `backup/quickshell-plugins/m3shapes/`

**Rust (alternativa):**
- `qml-rs` o bindings propios de Quickshell
- Más trabajo inicial pero memory-safe
- Lyon o rust-skia para la geometría de paths

---

## Cómo activar el plugin cuando esté listo

1. Compilar el plugin: `cmake -B build && cmake --build build`
2. Instalar el `.so` en un directorio que Quickshell tenga en su QML import path
3. Eliminar el directorio stub `backup/quickshell/M3Shapes/`
4. Quickshell cargará el plugin real automáticamente

Los archivos lock que usan `import M3Shapes` no necesitan cambios — la API es la misma.

---

## Referencias

- Quickshell docs: https://quickshell.outfoxxed.me/docs/
- Qt QML C++ Extensions: https://doc.qt.io/qt-6/qtqml-cppextensions-qmlextensionplugins.html
- QPainterPath: https://doc.qt.io/qt-6/qpainterpath.html
- Caelestia M3Shapes source: `/home/deadlock/Clones/shell/` (si está disponible)
