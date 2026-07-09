# Guía de Configuración LAMP en Arch Linux

**Entorno:** Arch Linux + Hyprland
**Versiones usadas:** Apache 2.4.66 · PHP 8.5.4 · MariaDB 12.2.2

---

## Índice

1. [Instalación de paquetes](#1-instalación-de-paquetes)
2. [Configuración de Apache](#2-configuración-de-apache)
3. [Configuración de PHP](#3-configuración-de-php)
4. [Configuración de MariaDB](#4-configuración-de-mariadb)
5. [Crear un VirtualHost para tu proyecto](#5-crear-un-virtualhost-para-tu-proyecto)
6. [Fix de systemd: ProtectHome](#6-fix-de-systemd-protecthome)
7. [Agregar el dominio local a /etc/hosts](#7-agregar-el-dominio-local-a-etchosts)
8. [Habilitar servicios al arranque](#8-habilitar-servicios-al-arranque)
9. [Verificación final](#9-verificación-final)
10. [Errores comunes y soluciones](#10-errores-comunes-y-soluciones)

---

## 1. Instalación de paquetes

```bash
sudo pacman -S apache php php-apache mariadb
```

---

## 2. Configuración de Apache

Archivo principal: `/etc/httpd/conf/httpd.conf`

### 2.1 Cambiar MPM de event a prefork

PHP con `libphp.so` no es thread-safe, por lo que **no es compatible con `mpm_event`**. Se debe usar `mpm_prefork`.

Busca estas líneas y edítalas así:

```apache
# Comentar event, descomentar prefork:
#LoadModule mpm_event_module modules/mod_mpm_event.so
LoadModule mpm_prefork_module modules/mod_mpm_prefork.so
```

Con sed en una sola línea:

```bash
sudo sed -i 's|^LoadModule mpm_event_module|#LoadModule mpm_event_module|; s|^#LoadModule mpm_prefork_module|LoadModule mpm_prefork_module|' /etc/httpd/conf/httpd.conf
```

### 2.2 Cargar el módulo PHP

Añadir después de la última línea `LoadModule`:

```apache
LoadModule php_module modules/libphp.so
```

### 2.3 Incluir la configuración de PHP

Añadir antes de la línea `IncludeOptional conf/conf.d/*.conf`:

```apache
Include conf/extra/php_module.conf
```

### 2.4 Definir ServerName global

Descomenta y edita esta línea para eliminar el warning de FQDN:

```apache
ServerName localhost
```

### 2.5 Habilitar el archivo de VirtualHosts

Verifica que esta línea esté descomentada en `httpd.conf`:

```apache
Include conf/extra/httpd-vhosts.conf
```

---

## 3. Configuración de PHP

El archivo `/etc/httpd/conf/extra/php_module.conf` ya viene preconfigurado al instalar `php-apache`. Su contenido debe ser:

```apache
# Required modules: dir_module, php_module

<IfModule dir_module>
    <IfModule php_module>
        DirectoryIndex index.php index.html
        <FilesMatch "\.php$">
            SetHandler application/x-httpd-php
        </FilesMatch>
        <FilesMatch "\.phps$">
            SetHandler application/x-httpd-php-source
        </FilesMatch>
    </IfModule>
</IfModule>
```

Si el archivo no existe, créalo con ese contenido en `/etc/httpd/conf/extra/php_module.conf`.

---

## 4. Configuración de MariaDB

### 4.1 Inicializar la base de datos

```bash
sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
```

### 4.2 Iniciar y habilitar el servicio

```bash
sudo systemctl enable --now mariadb
```

### 4.3 Securizar la instalación

```bash
sudo mariadb-secure-installation
```

Sigue las instrucciones: establece contraseña root, elimina usuarios anónimos, deshabilita login remoto de root, elimina la base de datos de prueba.

---

## 5. Crear un VirtualHost para tu proyecto

### 5.1 Crear el symlink del proyecto

Si tu proyecto está en una ruta larga (por ejemplo dentro de `~/Files/...`), crea un symlink en tu home para simplificar:

```bash
ln -s "/ruta/completa/a/tu/proyecto/MiProyecto" ~/MiProyecto
```

### 5.2 Configurar el VirtualHost

Edita `/etc/httpd/conf/extra/httpd-vhosts.conf` y agrega:

```apache
<VirtualHost *:80>
    DocumentRoot "/home/TU_USUARIO/MiProyecto"
    ServerName miproyecto.test

    ErrorLog "/var/log/httpd/miproyecto-error.log"

    <Directory "/home/TU_USUARIO/MiProyecto">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

> **Nota:** `AllowOverride All` es necesario si tu proyecto usa `.htaccess` (frameworks como Laravel, Symfony, etc.).

### 5.3 Dar acceso a Apache al home del usuario

Apache corre como usuario `http`. Necesita permiso de traversal en tu directorio home:

```bash
# Agregar el usuario http al grupo de tu usuario
sudo usermod -aG TU_USUARIO http

# Dar permiso de ejecución (traversal) al grupo en tu home
chmod g+x /home/TU_USUARIO
```

> **Importante:** Esto es necesario **antes** de iniciar/reiniciar Apache. Si ya está corriendo, reinícialo después.

---

## 6. Fix de systemd: ProtectHome

Por defecto, systemd bloquea el acceso de Apache a `/home` mediante la directiva `ProtectHome=on`. Hay que sobreescribirla con un drop-in:

```bash
sudo mkdir -p /etc/systemd/system/httpd.service.d
sudo tee /etc/systemd/system/httpd.service.d/override.conf << 'EOF'
[Service]
ProtectHome=off
EOF
sudo systemctl daemon-reload
```

> Este paso es **crítico** y es el error más difícil de diagnosticar. Sin esto, Apache devuelve 403 aunque todos los permisos del filesystem estén correctos.

---

## 7. Agregar el dominio local a /etc/hosts

```bash
sudo tee -a /etc/hosts << 'EOF'
127.0.0.1    miproyecto.test
EOF
```

Verifica que quedó correctamente:

```bash
grep miproyecto /etc/hosts
```

---

## 8. Habilitar servicios al arranque

```bash
sudo systemctl enable httpd
sudo systemctl enable mariadb
```

Para iniciarlos ahora mismo:

```bash
sudo systemctl start httpd
sudo systemctl start mariadb
```

---

## 9. Verificación final

### Verificar configuración de Apache sin errores:

```bash
httpd -t
```

Debe responder: `Syntax OK`

### Verificar módulos cargados:

```bash
httpd -M | grep -E "php|rewrite|prefork"
```

### Probar el sitio:

```bash
curl -s -o /dev/null -w "%{http_code}" http://miproyecto.test/
```

Respuesta esperada: `200` (o `403` solo si no hay `index.php`/`index.html` en el directorio raíz del proyecto).

### Probar PHP:

Crea un archivo `/home/TU_USUARIO/MiProyecto/info.php` con:

```php
<?php phpinfo();
```

Ábrelo en el navegador: `http://miproyecto.test/info.php`
Elimínalo después de verificar (nunca dejarlo en producción).

---

## 10. Errores comunes y soluciones

### 403 Forbidden — Permission denied (filesystem path '/home/...')

**Causa:** `ProtectHome=on` en systemd o permisos insuficientes en el home.
**Solución:** Ver [sección 6](#6-fix-de-systemd-protecthome) y [sección 5.3](#53-dar-acceso-a-apache-al-home-del-usuario).

---

### Apache falla al iniciar: "PHP Module is not compiled to be threadsafe"

**Causa:** Se está usando `mpm_event` (threaded) con `libphp.so` (NTS).
**Solución:** Cambiar a `mpm_prefork`. Ver [sección 2.1](#21-cambiar-mpm-de-event-a-prefork).

---

### Warning: "Could not reliably determine the server's fully qualified domain name"

**Causa:** No hay `ServerName` global definido.
**Solución:** Agregar `ServerName localhost` en `httpd.conf`. Ver [sección 2.4](#24-definir-servername-global).

---

### DocumentRoot does not exist (warning al iniciar)

**Causa:** Apache se inició antes de que existiera el symlink, o la ruta es incorrecta.
**Solución:** Verifica que el symlink existe con `ls -la ~/MiProyecto` y reinicia Apache.

---

### PHP no se ejecuta (se descarga o muestra código fuente)

**Causa:** El módulo PHP no está cargado o `php_module.conf` no está incluido.
**Solución:** Verificar secciones [2.2](#22-cargar-el-módulo-php) y [2.3](#23-incluir-la-configuración-de-php).

---

## Resumen de archivos modificados

| Archivo | Cambio |
|---|---|
| `/etc/httpd/conf/httpd.conf` | MPM prefork, LoadModule php, Include php_module.conf, ServerName |
| `/etc/httpd/conf/extra/httpd-vhosts.conf` | VirtualHost del proyecto |
| `/etc/httpd/conf/extra/php_module.conf` | Configuración de PHP para Apache (ya existe) |
| `/etc/systemd/system/httpd.service.d/override.conf` | Deshabilitar ProtectHome |
| `/etc/hosts` | Dominio local del proyecto |
