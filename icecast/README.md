# Icecast Server
https://icecast.org

### Command to fetch script
```
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/icecast/icecast-install.sh
```

Don't forget to
```
chmod +x icecast-install.sh
```

## Notes
- you cannot run icecast as root
- you must change the user it runs as, uncomment the "changeowner" section in the icecast.xml file, and `chown -R user:group /var/log/icecast` for it to run (change user:group to whichever user and group you want it to run as) 

## Variables
These are the variables that are available to change along with their defaults and a description of what they do. Other variables should be left at default unless you have a good reason to change them.
- none

## Mount points (should be mounted outside the jail)
- `/usr/local/etc/icecast` - config directory

## Jail Properties
- none


