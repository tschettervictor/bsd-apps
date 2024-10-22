# Jellyfin
https://jellyfin.org

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/jellyfin/jellyfin-install.sh
```

Don't forget to
```
chmod +x jellyfin-install.sh
```

## Install Notes
- Jellyfin has not been tested to see which mount points need to persist if a jail needs to be rebuilt

## Variables
These are the variables that are available to change along with their defaults and a description of what they do. Other variables should be left at defalut unless you have a good reason to change them.
- none

## Mount points (should be mounted outside the jail)
- not tested with or without mount points

## Jail Properties
- allow_mlock=1
