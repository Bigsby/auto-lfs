#!/bin/bash

if [ -z ${LFS+x} ]; 
    then 
        echo "LFS is not set."; 
        exit 1;
    else
        if [ -d "$LFS" ]; 
        then exit 0;
        else 
            echo "$LFS directory does not exist."
            exit 1;
        fi
fi