# ocr

Seleccionás una región de la pantalla, extrae el texto con tesseract y lo copia al clipboard.

## Deps

```bash
sudo pacman -S grim slurp hyprpicker tesseract wl-clipboard
# Datos de idioma (instalar los que uses):
sudo pacman -S tesseract-data-eng tesseract-data-spa
```

## Instalar

```bash
ln -sf ~/Files/Configuraciones/ocr/scripts/ocr ~/.local/bin/
```

## Uso

```bash
ocr
# Seleccionás la región → el texto queda en clipboard
```

## Variables de entorno

| Variable | Default | Descripción |
|---|---|---|
| `OCR_LANGS` | `eng` | Idioma(s) de tesseract. Múltiples: `eng+spa` |

## Hyprland binding sugerido

```
bind = SUPER, T, exec, ocr
```
