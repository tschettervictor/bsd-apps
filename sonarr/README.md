# Sonarr
https://sonarr.tv

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/sonarr/sonarr-install.sh
```

Don't forget to
```
chmod +x sonarr-install.sh
```

## Variables
These are the variables that are available to change along with their defaults and a description of what they do. Other variables should be left at default unless you have a good reason to change them.
- none

## Mount points (should be mounted outside the jail)
- `/usr/local/sonarr` - data directory

## Jail Properties
- allow_mlock=1
