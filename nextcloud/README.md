# Nextcloud
https://nextcloud.com

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/nextcloud/nextcloud-install.sh
```

Don't forget to
```
chmod +x nextcloud-install.sh
```

## Variables

DATA_PATH="/mnt/data"
  - data directory will be stored here (currently defaults to `/mnt/data`)

## Mount points (should be mounted outside the jail)
  - `/mnt/files` - files directory
  - `/usr/local/www/nextcloud/config` - config directory
  - Database
    - `/var/db/mysql` - database directory for mariadb
    - `/var/db/postgres` - database directory for postgresql
  - `/usr/local/www/nextcloud/config` - themes directory
## Jail Properties
  - none

