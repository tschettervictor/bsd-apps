# Minio
https://min.io

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/minio/minio-install.sh
```

Don't forget to
```
chmod +x minio-install.sh
```

## Variables
These are the variables that are available to change along with their defaults and a description of what they do. Other variables should be left at default unless you have a good reason to change them.
- none

## Mount points (should be mounted outside the jail)
- `/var/db/minio` - disks directory
- `/usr/local/etc/minio` - config/certs directory

## Jail Properties
- none
