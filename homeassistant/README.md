# Homeassistant
https://home-assistant.io

# Status
  - working as of September 18, 2024

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/homeassistant/homeassistant-install.sh
```

Don't forget to
```
chmod +x homeassistant-install.sh
```

## Install Notes
- this is a completely unsupported install of Homeassistant Core. It may work, and it may not work.
It used to work fine, but as of 2024 it's been tough keeping a jailed version going.

## Variables
These are the variables that are available to change along with their defaults and a description of what they do. Other variables should be left at default unless you have a good reason to change them.

PYTHON_VERSION
- python version to use (currently defaults to 311)

## Mount points (should be mounted outside the jail)
- `/home/homeassistant/config` - config directory

## Jail Properties
- none
