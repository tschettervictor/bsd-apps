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
- the mount point below is only for jellyfin settings and metadata, not media files
- media files should be mounted into `/mnt/media` or a similar directory

## Variables
These are the variables that are available to change along with their defaults and a description of what they do. Other variables should be left at default unless you have a good reason to change them.
- none

## Mount points (should be mounted outside the jail)
- `/var/db/jellyfin` - data directory

## Jail Properties
- allow_mlock=1
