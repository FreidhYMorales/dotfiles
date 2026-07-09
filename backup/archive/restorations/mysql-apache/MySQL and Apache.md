# Instalacion de MySQL y Apache para proyectos en localhost

Primero hay que instalar las dependencias y herramientas que vamos a usar.

```bash
sudo pacman -S apache php php-apache php-gd php-intl php-snmp mariadb
```

## Instalacion de mariadb

Verificar la instalacion de las dependencias con el comando anterior y luego ejecutar los siguientes comandos para iniciar mariadb:

```bash
#Ejecutar este comando para inicializar los directorios de datos
sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql

#Habilitar los servicios de mariadb
sudo systemctl start mariadb
sudo systemctl enable mariadb

#Asegurar la instalacion de mariadb
sudo mariadb-secure-installation

#Para correr mariadb por primera vez ejecurtar con sudo, la contraseña de root es la misma que la del usuario.
sudo mariadb -u root -p
```

Se puede crear luego un usuario para no usar sudo e ingresar a mariadb.
