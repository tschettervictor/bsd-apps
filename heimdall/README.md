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

PHP_VERSION
  - php version to use (currently defaults to 83)

HEIMDALL_VERSION
  - Heimdall version to use (currently defaults to 2.6.1)

## Mount points (should be mounted outside the jail)
  - `/usr/local/www` - html directory

## Jail Properties
  - none
