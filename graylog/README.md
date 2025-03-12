# Graylog
https://graylog.org

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/graylog/graylog-install.sh
```

Don't forget to
```
chmod +x graylog-install.sh
```

## Variables
These are the variables that are available to change along with their defaults and a description of what they do. Other variables should be left at default unless you have a good reason to change them.

MONGODB_VERSION
- mongodb version to use (currently defaults to 60)

## Mount points (should be mounted outside the jail)
- `/usr/local/etc/graylog` - config directory
- `/var/db/graylog` - data directory
- `/usr/local/share/graylog` - plugin/journal directory

## Jail Properties
- allow.mlock (optional)
