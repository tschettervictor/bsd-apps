# Uptime-Kuma Monitoring Server
https://github.com/louislam/uptime-kuma

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/uptime-kuma/uptime-kuma-install.sh
```

Don't forget to
```
chmod +x uptime-kuma-install.sh
```

## Variables
These are the variables that are available to change along with their defaults and a description of what they do. Other variables should be left at defalut unless you have a good reason to change them.

APP_VERSION
- app version to install (defaults to latest)

NODE_VERSION
- node version to use (currently defaults to 18)

DATA_PATH
- data will be stored here (currently defaults to `/mnt/data`)

## Mount points (should be mounted outside the jail)
- `/mnt/data` - data directory

## Jail Properties
- none
