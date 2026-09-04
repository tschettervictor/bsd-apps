![opencloud](https://github.com/tschettervictor/bsd-apps/actions/workflows/opencloud.yml/badge.svg)
# OpenCloud
https://opencloud.eu

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/master/opencloud/opencloud-install.sh
```

Don't forget to
```
chmod +x opencloud-install.sh
```

## Variables
These are the variables that are available to change along with their defaults and a description of what they do. Other variables should be left at defalut unless you have a good reason to change them.

APP_VERSION
- app version to install (defaults to latest)

NODE_VERSION
- node version to use (currently defaults to 24)

DATA_PATH
- data will be stored here (currently defaults to `/mnt/data`)

HOST_NAME
- sets the hostname to use for the webserver
- must be set to your FQDN ie: my.domain.com or IP address

## Mount points (should be mounted outside the jail)
- `/mnt/data` - data directory
- `/usr/local/etc/opencloud` - config directory

## Jail Properties
- none
