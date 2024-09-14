# Nextcloud
https://nextcloud.com

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/nextcloud/nextcloud-install.sh
```

Don't forget to
```
chmod +x nextcloud-install.sh
```

## Variables

These are the variable that are available to change along with their defaults and a description of what it does.

HOST_NAME (sets the hostname to use for the webserver) - must be set to your FQDN ie: my.domain.com

TIME_ZONE (sets the timezone, see http://php.net/manual/en/timezones.php) - must be set

DATABASE (set your preffered database, currently defaults to mariadb)

NEXTCLOUD_VERSION (currently defaults to 29)

PHP_VERSION (currently defaults to 83)

COUNTRY_CODE (2 letter ISO code for your country, currently defaults to CA)

### Cerificate Configuration

Caddy is a webserver that can do automatic TLS and HTTPS for you. You should enable one AND ONLY ONE of the following 4 CERT confiurations to tell the script how you want Caddy to work.

  - NO_CERT (default, no certificate will be created, http access)
  - STANDALONE_CERT (fully working cert, must own a domain, and have ports 80 and 443 forwarded to your jail)
  - SELFSIGNED_CERT (generates a self-signed cert for use with https)
  - DNS_CERT
      - must be used together with CERT_EMAIL DNS_TOKEN and DNS_PLUGIN
      - must own a domain that allows DNS validation
      - will generate a DNS validated cert
  - DNS_PLUGIN (set this to a supported DNS plugin, see caddy docs for details) -only used with DNS_CERT
  - DNS_TOKEN (must have "Zone / Zone / Read" and "Zone / DNS / Edit" permissions on the domain you are using with Caddy) - only used with DNS_CERT  
  - CERT_EMAIL (your email to receive cert expiry) - used with DNS_CERT and STANDALONE_CERT

All of the above variable should be changed to fit your environment. For more detailed documentation, see https://github.com/danb35/freenas-iocage-nextcloud

## Mount points (should be mounted outside the jail)
  - `/mnt/files` - files directory
  - `/usr/local/www/nextcloud/config` - config directory
  - Database (mount ONLY ONE depending on your database choice)
    - `/var/db/mysql` - database directory for mariadb
    - `/var/db/postgres` - database directory for postgresql
  - `/usr/local/www/nextcloud/config` - themes directory

## Jail Properties
  - none

