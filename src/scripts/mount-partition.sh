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

echo "Checking params..."

blk=$(lsblk -l)

echo "Setting up $1$2 on $3"

fdisk $1
# n and all defaults

mkfs -t ext4 $1$2
mkdir $3

nano fstab
# /dev/sdb1       /mnt/lfs       ext4     defaults       0     0
mount -a
