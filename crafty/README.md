![CI](https://github.com/tschettervictor/bsd-apps/actions/workflows/crafty.yml/badge.svg)
# Crafty Controller
https://craftycontroller.com

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/crafty/crafty-install.sh
```

Don't forget to
```
chmod +x crafty-install.sh
```

## Install Notes
- after initialization, enter the WebUI, and set the servers directory to `/var/games/minecraft/servers` under Panel Settings > Global Servers Directory

## Updating
- this script include the `-u|--update` flag to easily update the app. Simply run `./crafty-install.sh --update` overtop an existing installation

## Variables
These are the variables that are available to change along with their defaults and a description of what they do. Other variables should be left at defalut unless you have a good reason to change them.

OPENJDK_VERSION
- openjdk version to use (currently defaults to 25)

PYTHON_VERSION
- python version to use (currently defaults to 312)

TIME_ZONE
- sets the timezone, see http://php.net/manual/en/timezones.php)
- must be set (defaults to America/Edmonton)

## Mount points (should be mounted outside the jail)
- `/var/games/minecraft/servers` - server directory (see Install Notes above)

## Jail Properties
- allow.mount.procfs
- allow.mount.linprocfs
