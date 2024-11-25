# bsd-apps

Collection of scripts to install popular applications inside FreeBSD jails, or FreeBSD host system.

Each application has a README file which explains some necessary steps before running the script.

# Setup

These scripts are designed to work inside any jail manager or FreeBSD host system. In order to get up and running, here are the necessary steps
  1. Create a jail using your preferred jail manager
  2. Read the insructions in each apps README file to see
     - which jail properties need to be set, if any
     - which directories need to be mounted, if you so choose
     - which variables need to be set, if any
  3. Mount your directories and set your properties and variables as needed
     - the variables are set at the top of the app script
  4. Start the jail, fetch the script, set variable values inside the script, and run it

It is not necessary to do any mounting if you choose not to. It just makes it easy to rebuild jails if the need comes up.
All jail managers have a way to set jail properties and mount directories. Check documentation.

# Tips

I like to structure my data directories that I am mounting as below

  - apps
    - app1
      - data
      - otherdata
    - app2
      - config
      - data
      - files
    - app3
      - data

This enables me to mount the corresponding directories into the jail, and keep things organized.

# Important

## Mount points

All of the scripts are designed to work with mount points. Every bit of data that is necessary for a reinstall is included in each apps README file. This means that jails can be destroyed and rebuilt without losing data.

If you do not want to use mount points, the script will install the apps and its data inside the jail and everything will work normally. But be warned, when you destroy the jail, the data inside it will be lost.

Mount points make it easy to destroy and recreate jails without losing data. Each application has a list of mount points that must be mounted if you choose to store all the data outside the jail. These scripts have all been tested by doing an initial install, then a reinstall. If the data is mounted into the jail on a reinstall, the script will skip certain steps to prevent data from being overwritten.

## Variables

Some of the scripts have variables that should be set before running. These could include passwords, server values, and database names. Most will be set randomly, but some require user intervention. Each applications README file will let you know what to do.

Variables that should be changed are listed on the README file of each app. Any variables that are not listed, should not be changed unless there is a really good reason to do so.

## Jail Properties

Some applications require certain jail properties to be activated. You will have to do so with whichever jail manager you are using. They all have a way to set jail properties.

### Set Properties Examples
  - `iocage set allow_sysvipc=1 jailname`
  - `bastille config jailname set allow_sysvipc 1`
  - `pot set-attr -p jailname -A sysvipc -V 1`

### Mount Examples
  - `iocage fstab -a jailname /path/on/host /path/inside/jail nullfs rw 0 0`
  - `bastille mount jailname /path/on/host /path/inside/jail nullfs rw 0 0`
  - `pot mount-in -p jailname -m /path/inside/jail -f nullfs -d /path/on/host`
