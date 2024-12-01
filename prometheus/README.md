# Prometheus
https://prometheus.io

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/prometheus/prometheus-install.sh
```

Don't forget to
```
chmod +x prometheus-install.sh
```

## Variables
These are the variables that are available to change along with their defaults and a description of what they do. Other variables should be left at defalut unless you have a good reason to change them.
- none

## Mount points (should be mounted outside the jail)
- `/var/db/prometheus` - data directory
- `/usr/local/etc/prometheus` - config directory

## Jail Properties
- none
