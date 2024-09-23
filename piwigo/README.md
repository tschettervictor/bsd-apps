# Piwigo Photo Gallery
https://piwigo.org

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/piwigo/piwigo-install.sh
```

Don't forget to
```
chmod +x piwigo-install.sh
```

## Install Notes
  - none

## Variables

PHP_VERSION
  - php version to use (currently defaults to 83)

MARIADB_VERSION
  - mariadb version to use (currently defaults to 106)

## Mount points (should be mounted outside the jail)
  - `/usr/local/www/piwigo/local/config` - config file directory (needed for database connection)
  - `/usr/local/www/piwigo/galleries` - galleries directory
  - `/usr/local/www/piwigo/uploads` - uploads directory
  - `/var/db/mysql` - database directory

## Jail Properties
  - none