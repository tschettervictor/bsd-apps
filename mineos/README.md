# MineOS Minecraft Server Management
https://wiki.codeemo.com

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/mineos/mineos-install.sh
```

Don't forget to
```
chmod +x mineos-install.sh
```

## Variables
These are the variables that are available to change along with their defaults and a description of what they do. Other variables should be left at defalut unless you have a good reason to change them.

PYTHON_VERSION
- python version to use (currenlty defaults to 311)

NODE_VERSION
- node version to use (currenlty defaults to 20)

JAVA_VERSION
- java version to use (currenlty defaults to 22)

## Mount points (should be mounted outside the jail)
- `/var/games/minecraft` - data directory

## Jail Properties
- mount_procfs=1
- mount_linprocfs=1
