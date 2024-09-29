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
- APP_URL inside the `.env` file must be set to the IP or hostname you use to access you installation, or you will encounter errors

## Variables
These are the variables that are available to change along with their defaults and a description of what they do. Other variables should be left at defalut unless you have a good reason to change them.

PHP_VERSION
- php version to use (currently defaults to 83)

MARIADB_VERSION
- mariadb version to use (currently defaults to 106)

LYCHEE_VERSION
- lychee version to download (currently defaults to 5.5.1)

TIME_ZONE
- (sets the timezone, see http://php.net/manual/en/timezones.php)
- must be set or script will exit


## Mount points (should be mounted outside the jail)
- `/usr/local/www/lychee` - web directory (includes config file)
- `/var/db/mysql` - database directory

## Jail Properties
- none
