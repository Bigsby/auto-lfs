#!/bin/bash

show_usage() {
    echo "Usage: $0 <disk> <partition> <mountingpoint>"
    echo ""
    echo "E.g.:"
    echo "$0 sdb 1 /mnt/lfs"
    exit
}

if [ "$#" -ne "3" ]; 
    then
        show_usage
fi

disk=$1
partition=$2
mount_point=$3

echo "Setting up $1$2 on $3"