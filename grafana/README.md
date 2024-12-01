# Grafana Dashboard
https://grafana.com

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/grafana/grafana-install.sh
```

Don't forget to
```
chmod +x grafana-install.sh
```

## Variables
These are the variables that are available to change along with their defaults and a description of what they do. Other variables should be left at default unless you have a good reason to change them.
- none

## Mount points (should be mounted outside the jail)
- `/usr/local/share/grafana` - data directory
- `/usr/local/etc/grafana` - config directory
- `/var/db/grafana` - database directory

## Jail Properties
- none
