# BastilleBSD

The applications included in this repo have the ability to be used with BastilleBSD. Each application has an included Bastillefile, which is needed to apply the "template" on top of a jail created by Bastille.

To bootstrap the bsd-apps repository, run the following command.

```
bastille bootstrap https://github.com/tschettervictor/bsd-apps
```

This will install the entire repo, and verify each template for use with your system.

To apply a template, run the following command. Replace `APP` with the name of the application you want to use.

```
bastille template jailname bsd-apps/APP
```

# Mount Points
Each application is set to install any data that should persist in a mount point outside the jail. This means you can run the template overtop a brand new jail, and pick up where you left off, providing your data is still present in the mount points.

The default mount path for all applications is `/apps/APPNAME`.

For example, the guacamole application will store its config directory at `/apps/guacamole/config` and the database at `/apps/guacamole/db` by default.

This can easily be overidden if you store your data in a different location. Simply run the following command with the included `--arg DATA_PATH=/my/path/to/guacamole`.

```
bastille template jailname bsd-apps/guacamole --arg DATA_PATH=/my/path/to/guacamole
```
