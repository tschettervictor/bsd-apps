# Apache Guacamole
https://guacamole.apache.org

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/guacamole/guacamole-install.sh
```

Don't forget to
```
chmod +x guacamole-install.sh
```

## Variables

MARIADB_VERSION
- mariadb version to use (currently defaults to 106)

## Mount points (should be mounted outside the jail)
- `/var/db/mysql` - database directory
- `/usr/local/etc/guacamole-client` - config/extensions directory

## Jail Properties
- none
