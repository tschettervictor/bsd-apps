# Homeassistant
https://home-assistant.io

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/homeassistant/homeassistant-install.sh
```

Don't forget to
```
chmod +x homeassistant-install.sh
```

## Install Notes

This is a completely unsupported install of Homeassistant Core. It may work, and it may not work.
It used to work fine, but as of 2024 it's been tough keeping a jailed version going.

## Variables

PYTHON_VERSION
  - python version to use (currently defaults to 311)

## Mount points (should be mounted outside the jail)
  - `/home/homeassistant/config` - config directory

## Jail Properties
  - none
