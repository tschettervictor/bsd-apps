# Dasherr Dashboard
https://github.com/erohtar/Dasherr

![CI](https://github.com/tschettervictor/bsd-apps/actions/workflows/dasherr.yml/badge.svg)

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/dasherr/dasherr-install.sh
```

Don't forget to
```
chmod +x dasherr-install.sh
```

## Variables
These are the variables that are available to change along with their defaults and a description of what they do. Other variables should be left at default unless you have a good reason to change them.

APP_VERSION
- dasherr version to download (currently defaults to 1.05.02)

## Mount points (should be mounted outside the jail)
- `/usr/local/www/dasherr` - data directory

## Jail Properties
- none
