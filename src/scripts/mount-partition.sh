#!/bin/bash

fdisk /dev/sdb
# n and all defaults

mkfs -t ext4 /dev/sdb1
mkdir /mnt/lfs

nano Fstab
# /dev/sdb1       /mnt/lfs       ext4     defaults       0     0
mount -a
