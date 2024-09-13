# Apache Guacamole
https://guacamole.apache.org

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/apache-guacamole/apache-guacamole-install.sh
```

Don't forget to
```
chmod +x apache-guacamole-install.sh
```

## Variables

MARIADB_VERSION
  - mariadb version to use (currently defaluts to 106)

## Mount points (should be mounted outside the jail)
  - `/var/db/mysql` - database directory

## Jail Properties
  - none
