# Zoneminder Video Monitoring
https://zoneminder.com

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/zoneminder/zoneminder-install.sh
```

Don't forget to
```
chmod +x zoneminder-install.sh
```

## Install Notes
- Zoneminder has not been tested to see which mount points need to persist if a jail needs to be rebuilt

## Variables
These are the variables that are available to change along with their defaults and a description of what they do. Other variables should be left at defalut unless you have a good reason to change them.

MYSQL_VERSION
- MYSQL database version to use (currently defaults to 80)

## Mount points (should be mounted outside the jail)
- none

## Jail Properties
- none
