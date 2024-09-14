# Zoneminder Video Monitoring
https://zoneminder.com

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/zoneminder/zoneminder-install.sh
```

Don't forget to
```
chmod +x zoneminder-install.sh
```

## Variables

MYSQL_VERSION
  - MYSQL database version to use (currently defaults to 80)

## Mount points (should be mounted outside the jail)
  - zoneminder has not been configured for mount points
  - only jailed install is supported at this time
  - please back up needed data befor destroying your zoneminder jail

## Jail Properties
  - none
