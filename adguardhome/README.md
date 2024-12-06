# AdGuard Home
https://adguard.com

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/adguardhome/adguardhome-install.sh
```

Don't forget to
```
chmod +x adguardhome-install.sh
```

## Variables
These are the variables that are available to change along with their defaults and a description of what they do. Other variables should be left at default unless you have a good reason to change them.
- none

## Mount points (should be mounted outside the jail)
- `/var/db/adguardhome` - data directory
- `/usr/local/etc/adguardhome` - config directory

## Jail Properties
- none