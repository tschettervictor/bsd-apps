# MYSQL/MariaDB/PostgreSQL Database

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/database/database-install.sh
```

Don't forget to
```
chmod +x database-install.sh
```

## Install Notes
  - set only ONE of the database types to 1

## Variables

MARIADB=0
  - set to 1 to install MariaDB database

MYSQL=0
  - set to 1 to install MySQL database

POSTGRESQL=0
  - set to 1 to install PGSQL database

MARIADB_VERSION
  - mariadb version to use (currently defaults to 106)

MYSQL_VERSION
  - mysql version to use (currently defaults to 81)

PGSQL_VERSION="15"
  - postgres version to use (currently defaults to 15)

DB_NAME=""
  - set your desired database name

DB_USER=""
  - set your desired database user

## Mount points (should be mounted outside the jail)
  - none

## Jail Properties
  - none
