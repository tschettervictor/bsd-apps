# Unifi Controller
https://ui.com

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/unifi/unifi-install.sh
```

Don't forget to
```
chmod +x unifi-install.sh
```

## Install Notes
- no mount points for unifi at this time, it's easier to back up and restore controller from webUI
- make sure to back up your controller data when reinstalling

## Variables
These are the variables that are available to change along with their defaults and a description of what they do. Other variables should be left at defalut unless you have a good reason to change them.

UNIFI_VERSION
- unifi version to use (currently defaults to 8)

## Mount points (should be mounted outside the jail)
- none

## Jail Properties
- none
