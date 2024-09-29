# Plex Media Server
https://plex.tv

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/plex/plex-install.sh
```

Don't forget to
```
chmod +x plex-install.sh
```

## Notes
- the mount point below is only for plex settings and metadata, not media files
- media files should be mounted into `/mnt/media` or a similar directory

## Variables
These are the variables that are available to change along with their defaults and a description of what they do. Other variables should be left at defalut unless you have a good reason to change them.

BETA
- set to 1 to use beta version of plex

## Mount points (should be mounted outside the jail)
- `/mnt/plex-data` - metadata, settings directory

## Jail Properties
- none
