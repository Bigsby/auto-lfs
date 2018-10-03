param(
    [Parameter(Mandatory=$true)][string]$name,
    [string]$os="Ubuntu_64",
    [int]$ram=4096,
    [int]$cpus=2,
    [int]$vram=128,
    [int]$disk_size=40960,
    [string]$disk_format="VDI",
    [string]$disk_controller="ide",
    [string]$controller_name="IDE"
)
function ShowUsage() {
    Write-Host "Usage:"
    Write-Host ("./" + $MyInvocation.MyCommand.Name)
    Write-Host "  [OS=osType \\]"    
    Write-Host "  [RAM=ram \\]"
    Write-Host "  [CPUS=cpus \\]"
    Write-Host "  [VRAM=vram \\]"
    Write-Host "  [DISK_SIZE=diskSize \\]"
    Write-Host "  [DISK_FORMAT=diskFormat \\]"
    Write-Host "  [SDISK_SIZE=secondaryDiskSize \\]"
    Write-Host "  [SDISK_NAME=secondaryDiskName \\]"
    Write-Host "  [DISK_FORMAT=diskFormat \\]"
    Write-Host "  [ISO=pathToIsoFile \\]"
    Write-Host "  [TARGET_FOLDER=pathToFolder \\]"
    Write-Host "  machineName"
    exit
}

if (-not [bool](Get-Command vboxmanage)) {
    exit
}

# NAME=$1
# TARGET_FOLDER=$(get_or_set "$TARGET_FOLDER" "TARGET_FOLDER" "$DEFAULT__MACHINE_FOLDER/$NAME")
# OS=$(get_or_set "$OS" "OS" "$DEFAULT_OS")
# RAM=$(get_or_set "$RAM" "RAM" $DEFAULT_RAM)
# CPUS=$(get_or_set "$CPUS" "CPUS" "$DEFAULT_CPUS")
# VRAM=$(get_or_set "$VRAM" "VRAM" "$DEFAULT_VRAM")
# DISK_SIZE=$(get_or_set "$DISK_SIZE" "PDISK" "$DEFAULT_DISK_SIZE")
# DISK_FORMAT=$(get_or_set "$DISK_FORMAT" "DISK_FORMAT" "$DEFAULT_DISK_FORMAT")
# DISK_EXTENSION=$(echo $DISK_FORMAT | tr A-Z a-z)
# DISK_PATH="$TARGET_FOLDER/$NAME.$DISK_EXTENSION"
# if [ -n "$SDISK_SIZE" ] && [ -n "$SDISK_NAME" ];
# then
#     SDISK_PATH="$TARGET_FOLDER/$SDISK_NAME.$DISK_EXTENSION"
# fi
# DISK_CONTROLLER=$(get_or_set "$DISK_CONTROLLER" "DISK_CONTROLLER" "$DEFAULT_DISK_CONTROLLER")
# DISK_CONTROLLER_NAME=$($DISK_CONTROLLER | tr a-z A-Z)


Write-Host "NAME:\t$name"
Write-Host "FOLDER:\t$TARGET_FOLDER"
Write-Host "OS:\t$os"
Write-Host "RAM:\t$ram"
Write-Host "CPUS:\t$cpus"
Write-Host "VRAM:\t$vram"
Write-Host "DCTRL:\t$disk_controller"
Write-Host "DISK:\t$disk_size MB\t$disk_format\t$DISK_PATH"

# if [ -n "$SDISK_PATH" ];
# then
#     echo -e "2DISK:\t$SDISK_SIZE MB\t$DISK_FORMAT\t$SDISK_PATH"
# fi

# if [ -n "$ISO" ];
# then
#     echo -e "ISO:\t$ISO"
# fi

echo ""
echo -n "Are these correct (Y/n)? "
Write-Host "Continue..."