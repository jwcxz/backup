System Backup
=============

Create a config file and run
    
    $ backup.sh config.cfg

Relevant config variables are explained in backup.sh.

This script is good for backing up a system to another directory, probably on
another drive.  It doesn't support encryption, but it does support incremental
backups.  It creates a new full backup every month and incremental backups for
the rest of that month.  You can override that behavior to force a full backup
by doing:

    $ mode=full backup.sh config.cfg
