# Heimdall Dashboard
https://github.com/linuxserver/heimdall

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/heimdall/heimdall-install.sh
```

Don't forget to
```
chmod +x heimdall-install.sh
```

## Variables
These are the variables that are available to change along with their defaults and a description of what they do. Other variables should be left at default unless you have a good reason to change them.

PHP_VERSION
- php version to use (currently defaults to 83)

APP_VERSION
- Heimdall version to use (currently defaults to 2.6.1)

## Mount points (should be mounted outside the jail)
- `/usr/local/www` - html directory

## Jail Properties
- none
