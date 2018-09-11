#!/bin/bash

check_disk_partition() {
    IFS=$'\n'
    local disk="$1"
    local partition_number="$2"
    local partition="$disk$partition_number"
    
    local blk=$(lsblk -l | grep sdb)
    local diskExists=
    local partitionExists=
    local partition_mounted=
    local diskcheck="^$disk .*disk"
    local partitioncheck="^$partition .*part"
    local mountcheck="(/.*)$"
    local mount_point=

    for line in $blk; do
        if [[ $line =~ $diskcheck ]]; then
            diskExists="1";
        elif [[ $line =~ $partitioncheck ]]; then
            partitionExists="1"
            if [[ $line =~ $mountcheck ]]; then
                partition_mounted="1"
                mount_point=${BASH_REMATCH[1]}
            fi
        fi
    done

    if [ "$diskExists" == "1" ]; then
        echo "Disk '$disk' exists."

        if [ "$partitionExists" == "1" ]; then
            echo "Partition '$partition' exists."

            if [ "$partition_mounted" == "1" ]; then
                echo "Partition '$partition' is mounted on '$mount_point'."
                else
                echo "Partition '$partition' is not mounted!"
            fi

        else
            echo "Partition '$partition' does not exist!"
        fi

    else
        echo "Disk '$disk' does not exist!"
    fi
}

result=$(check_disk_partition sdb 1)
echo $result