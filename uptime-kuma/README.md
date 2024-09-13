# Uptime-Kuma Monitoring Server
https://github.com/louislam/uptime-kuma

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/uptime-kuma/uptime-kuma-install.sh
```

Don't forget to
```
chmod +x uptime-kuma-install.sh
```

## Variables

DATA_PATH="/mnt/data"
  - data directory will be stored here (currently defaults to `/mnt/data`)

## Mount points (should be mounted outside the jail)
  - `/mnt/data` - data directory

## Jail Properties
  - none
