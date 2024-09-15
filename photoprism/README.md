# Photoprism
https://photoprism.com

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/photoprism/photoprism-install.sh
```

Don't forget to
```
chmod +x photoprism-install.sh
```
## Variables
These are the variables that are available to change along with their defaults and a description of what they do.
Other variables should be left at defalut unless you have a good reason to change them.

PHOTOPRISM_PKG 
  - sets the url to retrieve photoprism package

LIBTENSORFLOW_PKG
  - sets the url to retrieve libtensorflow package

## Mount points (should be mounted outside the jail)
  - `/mnt/photos` - photos directory
  - `/var/db/mysql` - database directory

## Jail Properties
  - none
