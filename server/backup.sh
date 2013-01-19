#!/bin/sh

configfile=`realpath $1 2>/dev/null`
if [[ ! -f "$configfile" ]]; then 
    echo "no config file found!"
    exit 1
fi

# some useful directories
scriptdir=`realpath $(dirname $0)`
configdir=`realpath $(dirname $1)`

# vars to config
target=""              # target server
target_dir=""          # remote directory to back up
backup_dir=""          # local directory to back up to
archive_dir="archives" # place to store archives
passfile=""            # secret key location

compression_algo="z"   # z for gzip, j for bz2, etc.
crypto_algo="-aes-256-cbc"
remote_shell="ssh"

# number of archives to keep (0 for unlimited)
keep_max=0

precmd () { false; }
postcmd () { false; }

# source config file
. $configfile

# in general, $archive should never be set, but allow for it just in case
[[ $archive ]] || archive=`date +"$backup_dir-%y-%m-%d_%H_%M.tar.gz.enc"`

echo "config:      $configfile"
echo "target:      $target"
echo "target_dir:  $target_dir"
echo "backup_dir:  $backup_dir"
echo "archive_dir: $archive_dir"
echo "archive:     $archive"
echo "passfile:    $passfile"

# look for unarchived dir
if [[ -d $backup_dir ]]; then
    echo "Using existing backup directory as a base."
else
    # if not found, try extract the latest archive
    latest_archive=`find "$archive_dir" -not -size 0 -name "$backup_dir-*" 2>/dev/null | sort | tail -n1`
    if [[ "$latest_archive" == "" ]]; then
        # if no archive found, just make the directory
        echo "No previous backup found.  Starting a new backup."
        mkdir "$backup_dir"
        chmod 700 "$backup_dir"
    else
        echo "Previous archive found.  Extracting and using that as a base."
        openssl enc $crypto_algo -in "$latest_archive" -d -k `cat $passfile` | tar x${compression_algo}f -
    fi
fi


precmd

# rsync
echo "Performing rsync..."
rsync --progress -aze "$remote_shell" "$target:$target_dir" "$backup_dir"
if [[ $? -ne 0 ]]; then
    echo "Error: rsync failed"
    exit 1
else
    echo "done"
fi

# archive
echo "Archiving backup..."
tar c${compression_algo}psf - "$backup_dir" | openssl enc $crypto_algo -out "$archive_dir/$archive" -k "`cat $passfile`"

if [[ $? -ne 0 ]]; then
    echo "Error: archiving failed"
    exit 1
else
    echo "done"
fi

# if there's a limit to the number of archives, only keep the last so-many
if [[ $keep_max != 0 ]]; then
    echo "Removing all but latest $keep_max archives"
    rm `ls -1 $archive_dir/$backup_dir-* | head -n -$keep_max`
fi

postcmd
