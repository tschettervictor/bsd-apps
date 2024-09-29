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
- initial setup from the WebUI requires you to change the database address to 127.0.0.1 instead of localhost, or it will fail

## Variables
These are the variables that are available to change along with their defaults and a description of what they do. Other variables should be left at defalut unless you have a good reason to change them.

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
