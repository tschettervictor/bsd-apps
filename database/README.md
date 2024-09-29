# MYSQL/MariaDB/PostgreSQL Database

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/database/database-install.sh
```

Don't forget to
```
chmod +x database-install.sh
```

## Notes
- set only ONE of the database types to 1

## Variables
These are the variables that are available to change along with their defaults and a description of what they do. Other variables should be left at defalut unless you have a good reason to change them.

MARIADB
- set to 1 to install MariaDB database

MYSQL
- set to 1 to install MySQL database

POSTGRESQL
- set to 1 to install PGSQL database

MARIADB_VERSION
- mariadb version to use (currently defaults to 106)

MYSQL_VERSION
- mysql version to use (currently defaults to 81)

PGSQL_VERSION
- postgres version to use (currently defaults to 15)

DB_NAME
- set your desired database name

DB_USER
- set your desired database user

## Mount points (should be mounted outside the jail)
- none

## Jail Properties
- none
