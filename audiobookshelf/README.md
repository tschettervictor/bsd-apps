![audiobookshelf](https://github.com/tschettervictor/bsd-apps/actions/workflows/audiobookshelf.yml/badge.svg)
# Audiobookshelf
https://audiobookshelf.org

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/master/audiobookshelf/audiobookshelf-install.sh
```

Don't forget to
```
chmod +x audiobookshelf-install.sh
```

## Variables
These are the variables that are available to change along with their defaults and a description of what they do. Other variables should be left at defalut unless you have a good reason to change them.

APP_VERSION
- app version to install (defaults to 2.36.0)

NODE_VERSION
- node version to use (currently defaults to 20)

DATA_PATH
- data will be stored here (currently defaults to `/mnt/data`)

## Mount points (should be mounted outside the jail)
- `/mnt/data` - data directory
- `/usr/local/etc/audiobookshelf` - config directory

## Jail Properties
- none
