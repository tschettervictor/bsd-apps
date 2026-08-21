# Immich
https://immich.app

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/immich/immich-install.sh
```

Don't forget to
```
chmod +x immich-install.sh
```

## Variables
These are the variables that are available to change along with their defaults and a description of what they do. Other variables should be left at defalut unless you have a good reason to change them.

TIME_ZONE
- sets the timezone, see http://php.net/manual/en/timezones.php)
- must be set

PG_VERSION
- postgres version to use (currently defaults to 18)

## Mount points (should be mounted outside the jail)
- `/var/db/immich` - immich-server data directory
- `/var/db/immich-ml` - immich-machine-learning cache directory
- `/var/db/postgres` - database directory for postgresql
- `/usr/local/etc/immich.env` - immich env file (optional, but keep if you have many variables)

## Jail Properties
- `sysvshm=new` - needed for postgres shared memory

