# xcompose

Secuencias de teclado para emojis y tipografía via XCompose.

## Instalar

```bash
ln -sf ~/Files/Configuraciones/xcompose/XCompose ~/.XCompose
```

Activar la tecla compose en Hyprland (`~/.config/hypr/input.conf`):

```
input {
    kb_options = compose:ralt
}
```

Recargar Hyprland (`hyprctl reload`) para que tome el cambio.

## Uso

Con AltGr como tecla compose:

| Secuencia | Resultado |
|---|---|
| AltGr → m → s | 😄 smile |
| AltGr → m → h | ❤️ heart |
| AltGr → m → y | 👍 yes |
| AltGr → m → n | 👎 no |
| AltGr → m → x | 🎉 celebrate |
| AltGr → m → p | 🙏 pray |
| AltGr → space → space | — em dash |

Ver `XCompose` para la lista completa (prefix `m` + letra).
