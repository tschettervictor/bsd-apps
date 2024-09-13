# OnlyOffice Document Server
https://onlyoffice.com

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/onlyoffice-documentserver/onlyoffice-documentserver-install.sh
```

Don't forget to
```
chmod +x onlyoffice-documentserver-install.sh
```

## Variables

PG_VERSION
  - postgres version to use (currently defaluts to 15)

## Mount points (should be mounted outside the jail)
  - none

## Jail Properties
  - allow_sysvipc=1
