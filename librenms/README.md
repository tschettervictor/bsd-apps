![librenms](https://github.com/tschettervictor/bsd-apps/actions/workflows/librenms.yml/badge.svg)
# LibreNMS
https://www.librenms.org

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/master/librenms/librenms-install.sh
```

Don't forget to
```
chmod +x librenms-install.sh
```

## Notes
- if you select `NO_CERT`, (see below) the script will set `SESSION_SECURE_COOKIE=false`. If you are going to set up
a reverse proxy or https of any kind AFTER INSTALLING WITH `NO_CERT` , you should set this to `true`. Any other `*_CERT`
option will leave this set to `true`.
- if you want to set up a reverse proxy in front of LibreNMS, you will have to make sure caddy trusts the proxy. See
https://caddyserver.com/docs/caddyfile/options#trusted-proxies for details. You will also have to set
`APP_TRUSTED_PROXIES=my.proxy.ip` in `.env`.
- for LibreNMS to generate proper URLs behind a reverse proxy, you should set `APP_URL=https://my.app.local` and
`ASSET_URL=https://my.app.local`. Also make sure caddy trusts proxies in front of it. See above. Again, for any `*_CERT` option
other than `NO_CERT`, these are automatically filled with `HOST_NAME`.
- for any change you make to the `.env` file, you will probably have to update the config. Do so by
running `su -m www -c 'cd /usr/local/www/librenms && lnms config:clear` then
`su -m www -c 'cd /usr/local/www/librenms && lnms config:cache`.

## Variables
These are the variables that are available to change along with their defaults and a description of what they do. Other variables should be left at default unless you have a good reason to change them.

HOST_NAME
- sets the hostname to use for the webserver
- must be set to your FQDN ie: my.app.local

TIME_ZONE
- sets the timezone, see http://php.net/manual/en/timezones.php)
- must be set

MARIADB_VERSION
- mariadb version to use (currently defaults to 123)

### Cerificate Configuration

Caddy is a webserver that can do automatic TLS and HTTPS for you. You should enable one AND ONLY ONE of the following 4 CERT configurations to tell the script how you want Caddy to work.

NO_CERT
- no certificate, http access only

STANDALONE_CERT
- fully working cert, must own a domain, and have ports 80 and 443 forwarded to your jail

SELFSIGNED_CERT
- generates a self-signed cert for use with https

DNS_CERT 
- DNS validated cert, https access
- must be used together with CERT_EMAIL DNS_TOKEN and DNS_PLUGIN
- must own a domain that allows DNS validation
- will generate a DNS validated cert

DNS_PLUGIN
- set this to a supported DNS plugin, see caddy docs for details
- only used with DNS_CERT

DNS_TOKEN
- must have "Zone / Zone / Read" and "Zone / DNS / Edit" permissions on the domain you are using with Caddy)
- only used with DNS_CERT 

CERT_EMAIL
- your email to receive cert expiry
- used with DNS_CERT and STANDALONE_CERT

If you do use any type of certificate with a domain, Caddy will obtain a staging certificate to not excede rate limits. Once you have confirmed things are working, run the script at `/root/remove-staging.sh` to acquire a valid certificate.

All of the above variables should be changed to fit your environment.

## Mount points (should be mounted outside the jail)
- `/var/db/mysql` - database directory
- `/usr/local/www/librenms/config` - config directory
- `/var/db/librenms` - rrd/graphs directory

## Jail Properties
- none
