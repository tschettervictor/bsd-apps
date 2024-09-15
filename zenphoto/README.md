# Zenphoto
https://zenphoto.com

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/zenphoto/zenphoto-install.sh
```

Don't forget to
```
chmod +x zenphoto-install.sh
```

## Install Notes
  - Reinstalling replaces the 'zp-core' and 'themes' directories, and the 'index.php' file according to the documentation. If you have modified a theme or installed a custom theme, please be sure to back them up before reinstalling.

## Variables

PHP_VERSION
  - php version to use (currently defaults to 83)

MARIADB_VERSION
  - mariadb version to use (currently defaults to 106)

ZP_VERSION
  - Zenphoto version to use (currently defaults to 1.6.4)

## Mount points (should be mounted outside the jail)
  - `/usr/local/www/zenphoto` - data directory
  - `/var/db/mysql` - database directory

## Jail Properties
  - none
