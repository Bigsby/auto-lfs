function show_usage() {
    echo >&2 "Usage:"
    echo >&2 "$ $0 machineName"
    exit;
}

if ! [ -h /usr/bin/vboxmanage ];
then
    echo "vboxmanage not found!";
    exit;
fi

if [ $# != 1 ];
then
    show_usage
fi

/usr/bin/vboxmanage unregistervm $1 --delete
