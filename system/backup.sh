#!/bin/bash

configfile=`realpath $1 2>/dev/null`
if [[ ! -f "$configfile" ]]; then 
    echo "no config file found!"
    exit 1
fi

# some useful directories
scriptdir=`realpath $(dirname $0)`
configdir=`realpath $(dirname $1)`

# vars to config
backupdir=  # directory to store backups
targetdir=  # directory to backup
prefix=     # backup prefix (e.g. "home")
excludes=   # list of exclusions (either as "-X excludefile" or as
            # "--exclude=pattern"s)

precmd() { false; }
postcmd() { false; }


# mode can be overriden to full to force a full backup (e.g. run 
#   mode=full ./backup.sh config)


# read in configuration
. $configfile


# ensure required vars are configured
if [[ "$backupdir" == "" || "$targetdir" == "" || $prefix == "" ]]; then
    echo "configuration incomplete"
    exit 1
fi

# print configuration
echo "backup dir: $backupdir"
echo "target dir: $targetdir"
echo "prefix    : $prefix"
echo "excludes  : $excludes"

# perform backup
timestamp=`date +'%y-%m-%d_%H-%M-%S'`
full_search=$backupdir/"$prefix-full-`date +'%y-%m'`-*.tgz"

# figure out whether to perform an incremental backup against a previous
# archive or a new full one
full_archive=`ls -1tr $full_search 2>/dev/null | tail -n 1` 
if [[ "$mode" == "full" ]]; then
    echo "type      : full (forced)"
    mode="full"
elif [[ "$full_archive" == "" ]]; then
    echo "type      : full"
    mode="full"
else
    echo "type      : incremental (against $full_archive)"
    mode="incr"
fi

# generate names for the new archive and incremental list
new_archive=$backupdir/$prefix-$mode-$timestamp.tgz
new_snar=${new_archive%.tgz}.snar
echo "archive   : $new_archive"
echo "incr list : $new_snar"

# if we're in incremental mode, copy the incremental listing to a new one
if [[ "$mode" == "incr" ]]; then
    full_snar=${full_archive%.tgz}.snar

    echo "copying old incremental list..."

    cp "$full_snar" "$new_snar" 
    
    if [[ $? -ne 0 ]]; then
        echo "copy failed!"
        exit 1
    else
        echo "done"
    fi
fi


precmd


echo "starting archive..."

tar -czp -g "$new_snar" -f "$new_archive" $excludes "$targetdir"

if [[ $? -ne 0 ]]; then
    echo "backup failed!"
    exit 1
else
    echo `du -h "$new_archive"`
    echo "done"
fi


postcmd
