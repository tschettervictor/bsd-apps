![librenms](https://github.com/tschettervictor/bsd-apps/actions/workflows/librenms.yml/badge.svg)
# LibreNMS
https://www.librenms.org

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/master/librenms/librenms-install.sh
```

Don't forget to
```
chmod +x librenms-install.sh
```

## Variables
These are the variables that are available to change along with their defaults and a description of what they do. Other variables should be left at default unless you have a good reason to change them.

MARIADB_VERSION
- mariadb version to use (currently defaults to 123)

## Mount points (should be mounted outside the jail)
- `/var/db/mysql` - database directory
- `/usr/local/www/librenms/.env` - env file
- `/usr/local/www/librenms/config.php` - config file
- `/var/db/librenms` - rrd/graphs directory

## Jail Properties
- none
