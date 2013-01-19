Server Backup
=============

Create a config file and run
    
    $ backup.sh config.cfg

Relevant config variables are explained in backup.sh.

I use this to backup a server over rsync.  This system supports compression and
encryption of the rsync'd directory, but does not allow for performing
incremental backups.
