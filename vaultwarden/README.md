# Vaultwarden
https://github.com/dani-garcia/vaultwarden

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/vaultwarden/vaultwarden-install.sh
```

Don't forget to
```
chmod +x vaultwarden-install.sh
```

## Variables
These are the variables that are available to change along with their defaults and a description of what they do. Other variables should be left at defalut unless you have a good reason to change them.

HOST_NAME
- sets the hostname to use for the webserver
- must be set to your FQDN ie: my.domain.com

PYTHON_VERSION
- python version to use (currently defaults to 311)

### Cerificate Configuration

Vaultwarden requires an https connection for the web vault and clients. This script uses Caddy as the webserver to achieve this.

Caddy is a webserver that can do automatic TLS and HTTPS for you. You should enable one AND ONLY ONE of the following 4 CERT configurations to tell the script how you want Caddy to work. Unless you are going to put Vaultwarden behind a reverse proxy, you should not ever choose NO_CERT.

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
- must have "Zone / Zone / Read" and "Zone / DNS / Edit" permissions on the domain you are using with Caddy
- only used with DNS_CERT 

CERT_EMAIL
- your email to receive cert expiry
- used with DNS_CERT and STANDALONE_CERT

If you do use any type of certificate with a domain, Caddy will obtain a staging certificate to not excede rate limits. Once you have confirmed things are working, run the script at `/root/remove-staging.sh` to acquire a valid certificate.

All of the above variables should be changed to fit your environment.

## Mount points (should be mounted outside the jail)
- `/usr/local/www/vaultwarden/data` - data directory

## Jail Properties
- none
