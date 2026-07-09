# Instalacion de MPD y configuraciones de NCMPCPP

Como reproductor de musica principal se utiliza el servicio de MPD junto al cliente de control NCMPCPP.
Para instalarlos ejecutar los siguientes comandos:

```bash
sudo pacman -S mpd ncmpcpp mpd-mpris playerctl
```

Luego debemos inicializar el servicio de mpd con el siguiente comando:

```bash
systemctl --user enable --now mpd
```

**_Como mpd es un servicio este siempre se esta ejecutando en segundo plano, asi que cerrar ncmpcpp no afecta su funcionamiento, y sigue funcionando normalmente_**

## Guia de uso rápido (Command Key)

| Tecla | Acción                                              |
| ----- | --------------------------------------------------- |
| F1    | Ayuda completa de atajos                            |
| 1/2   | Cambiar entre Playlist actual y Browser de archivos |
| 4/8   | Buscar musica / COnfiguracion de visualizador       |
| u     | Actualizar la base de datos(Database Update)        |
| a     | Añadir canción o carpeta a la playlist actual       |
| s     | Detener reproduccion (Stop)                         |
| p     | Pausar reproduccion (Pause)                         |

**_\*En caso de que se agreguen nuevas canciones siempre usar la tecla u para que aparezcan las nuevas canciones_**
