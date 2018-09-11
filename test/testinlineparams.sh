#! /bin/bash

echo "$$0 $0"
echo "Number of params: $#"
count=1
while [ "$1" != "" ]; do
    echo "param $count $1"
    count=$(($count+1))
    shift
done