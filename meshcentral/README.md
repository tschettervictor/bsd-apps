# MeshCentral Management Server
https://meshcentral.com/

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/meshcentral/meshcentral-install.sh
```

Don't forget to
```
chmod +x meshcentral-install.sh
```

## Variables

NODE_VERSION
  - node version to use (currently defaluts to 20)

## Mount points (should be mounted outside the jail)
  - `/usr/local/meshcentral/meshcentral-data` - data
  - `/usr/local/meshcentral/meshcentral-files` - files
  - `/usr/local/meshcentral/meshcentral-backups` - backups

## Jail Properties
  - none
