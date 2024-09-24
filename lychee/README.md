# Lychee Photo Gallery
https://github.com/LycheeOrg/Lychee

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/lychee/lychee-install.sh
```

Don't forget to
```
chmod +x lychee-install.sh
```

## Install Notes
  - none

## Variables

PHP_VERSION
  - php version to use (currently defaults to 83)

MARIADB_VERSION
  - mariadb version to use (currently defaults to 106)

## Mount points (should be mounted outside the jail)
  - `/usr/local/www/lychee` - web directory (includes config file)
  - `/var/db/mysql` - database directory

## Jail Properties
  - none
