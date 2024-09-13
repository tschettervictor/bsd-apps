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

SERVER
  - set to IP or hostname of jail

## Mount points (should be mounted outside the jail)
  - `var/db/rustdesk-server` - key file directory

## Jail Properties
  - none
