# bsd-apps
Collection of scripts to install popular applications inside FreeBSD jails, or FreeBSD host system.

Each application has a README file which explains some necessary steps before running the script.

# Important

## Mount points

Mount points make it easy to destroy and recreate jails without losing data. Each application has a list of mount points that must be mounted if you choose to store all the data outside the jail. These scripts have all been tested by doing an initial install, then a reinstall. If the data is mounted into the jail on a reinstall, the script will skip certain steps to prevent data from being overwritten.

If you do not mount the data outside the jail, then it will be lost if you destroy the jail.

## Variables

Some of the scripts have variables that should be set before running. These could include passwords, server values, and database names. Most will be set randomly, but some require user intervention. Each applications README file will let you know what to do.

## Jail Properties

Some applications require certain jail properties to be activated. You will have to do so with whichever jail manager you are using. They should all have a way to set jail properties.
