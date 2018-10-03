DEFAULT_OS="Ubuntu_64"
DEFAULT_RAM="4096"
DEFAULT_CPUS="2"
DEFAULT_VRAM="128"
DEFAULT_DISK_SIZE="40960"
DEFAULT_DISK_FORMAT="VDI"
DEFAULT_DISK_CONTROLLER="ide"
DEFAULT_CD_CONTROLLER_NAME="IDE"

function show_usage() {
    echo >&2 "Usage:"
    echo >&2 "$ [OS=osType \\]"    
    echo >&2 "  [RAM=ram \\]"
    echo >&2 "  [CPUS=cpus \\]"
    echo >&2 "  [VRAM=vram \\]"
    echo >&2 "  [DISK_SIZE=diskSize \\]"
    echo >&2 "  [DISK_FORMAT=diskFormat \\]"
    echo >&2 "  [SDISK_SIZE=secondaryDiskSize \\]"
    echo >&2 "  [SDISK_NAME=secondaryDiskName \\]"
    echo >&2 "  [DISK_FORMAT=diskFormat \\]"
    echo >&2 "  [ISO=pathToIsoFile \\]"
    echo >&2 "  [TARGET_FOLDER=pathToFolder \\]"
    echo >&2 "  $0 machineName"
    exit;
}

function get_or_set() {
    VALUE=$1
    PARAM=$2
    DEFAULT=$3
    if [ -z "$VALUE" ];
    then
        [ -n "$DEBUG" ] && echo >&2 "Defaulting $PARAM to $DEFAULT"
        echo $DEFAULT
    else
        echo $VALUE
    fi
}

if ! [ -h /usr/bin/vboxmanage ];
then
    echo "vboxmanage not found!";
    exit;
else
    DEFAULT__MACHINE_FOLDER=$(vboxmanage list systemproperties | grep "Default machine folder" | cut -d" " -f13)
fi

if [ $# != 1 ];
then
    show_usage
fi

NAME=$1
TARGET_FOLDER=$(get_or_set "$TARGET_FOLDER" "TARGET_FOLDER" "$DEFAULT__MACHINE_FOLDER/$NAME")
OS=$(get_or_set "$OS" "OS" "$DEFAULT_OS")
RAM=$(get_or_set "$RAM" "RAM" $DEFAULT_RAM)
CPUS=$(get_or_set "$CPUS" "CPUS" "$DEFAULT_CPUS")
VRAM=$(get_or_set "$VRAM" "VRAM" "$DEFAULT_VRAM")
DISK_SIZE=$(get_or_set "$DISK_SIZE" "PDISK" "$DEFAULT_DISK_SIZE")
DISK_FORMAT=$(get_or_set "$DISK_FORMAT" "DISK_FORMAT" "$DEFAULT_DISK_FORMAT")
DISK_EXTENSION=$(echo $DISK_FORMAT | tr A-Z a-z)
DISK_PATH="$TARGET_FOLDER/$NAME.$DISK_EXTENSION"
if [ -n "$SDISK_SIZE" ] && [ -n "$SDISK_NAME" ];
then
    SDISK_PATH="$TARGET_FOLDER/$SDISK_NAME.$DISK_EXTENSION"
fi
DISK_CONTROLLER=$(get_or_set "$DISK_CONTROLLER" "DISK_CONTROLLER" "$DEFAULT_DISK_CONTROLLER")
DISK_CONTROLLER_NAME=$($DISK_CONTROLLER | tr a-z A-Z)

echo -e "NAME:\t $NAME"
echo -e "FOLDER:\t$TARGET_FOLDER"
echo -e "OS:\t$OS"
echo -e "RAM:\t$RAM"
echo -e "CPUS:\t$CPUS"
echo -e "VRAM:\t$VRAM"
echo -e "DCTRL:\t$DISK_CONTROLLER"
echo -e "DISK:\t$DISK_SIZE MB\t$DISK_FORMAT\t$DISK_PATH"

if [ -n "$SDISK_PATH" ];
then
    echo -e "2DISK:\t$SDISK_SIZE MB\t$DISK_FORMAT\t$SDISK_PATH"
fi

if [ -n "$ISO" ];
then
    echo -e "ISO:\t$ISO"
fi

echo ""
echo -n "Are these correct (Y/n)? "
read response
if [ "$response" = "n" ] || [ "$response" = "N" ];
then
    exit
fi

echo "Creating VM..."
/usr/bin/vboxmanage createvm --name "$NAME" --ostype $OS --register
/usr/bin/vboxmanage modifyvm "$NAME" --cpus $CPUS --memory $RAM --vram $VRAM
echo "Creating CD Controller..."
/usr/bin/vboxmanage storagectl "$NAME" --name "$DEFAULT_CD_CONTROLLER_NAME" --add ide --controller PIIX4
echo "Creating disk controller..."
/usr/bin/vboxmanage storagectl "$NAME" --name "$DISK_CONTROLLER_NAME" --add sata --controller IntelAhci
echo "Creating primary disk..."
/usr/bin/vboxmanage createmedium disk --filename "$DISK_PATH" --size $DISK_SIZE --format $DISK_FORMAT
/usr/bin/vboxmanage storageattach "$NAME" --storagectl "$DISK_CONTROLLER_NAME" --port 0 --device 0 --type hdd --medium "$DISK_PATH"
if [ -n "$SDISK_PATH" ];
then 
    echo "Creating primary disk..."
    SDISK_PATH="$TARGET_FOLDER/$SDISK_NAME.$DISK_EXTENSION"
    /usr/bin/vboxmanage createmedium disk --filename "$SDISK_PATH" --size $SDISK_SIZE --format $DISK_FORMAT
    /usr/bin/vboxmanage storageattach "$NAME" --storagectl "$DISK_CONTROLLER_NAME" --port 1 --device 0 --type hdd --medium "$SDISK_PATH"
fi
if [ -n "$ISO" ];
then
    /usr/bin/vboxmanage storageattach "$NAME" --storagectl "$DEFAULT_CD_CONTROLLER_NAME" --port 0 --device 0 --type dvddrive --medium "$ISO"
fi

echo "Starting VM..."
/usr/bin/vboxmanage startvm "$NAME"
