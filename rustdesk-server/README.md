# Self Hosted Rustdesk Server
https://rustdesk.com/

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/rustdesk-server/rustdesk-server-install.sh
```

Don't forget to
```
chmod +x rustdesk-server-install.sh
```

## Variables
These are the variables that are available to change along with their defaults and a description of what they do. Other variables should be left at defalut unless you have a good reason to change them.

SERVER
- set to IP or hostname of jail
- should match the IP or hostname you will use to connect if you plan to use external access

## Mount points (should be mounted outside the jail)
- `var/db/rustdesk-server` - key file directory

## Jail Properties
- none
