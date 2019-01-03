#!/bin/bash

# colors
ENDC='[0m'

RED='[00;31m'
GREEN='[00;32m'
YELLOW='[00;33m'
BLUE='[00;34m'
PURPLE='[00;35m'
CYAN='[00;36m'
LIGHTGRAY='[00;37m'

LRED='[01;31m'
LGREEN='[01;32m'
LYELLOW='[01;33m'
LBLUE='[01;34m'
LPURPLE='[01;35m'
LCYAN='[01;36m'
WHITE='[01;37m'


PROMPT=">"

# nn = no newline
log-nn() {
	printf "$PROMPT ${@}$ENDC"
}

log() {
    log-nn "$@\n"
}

fatal() {
    log "$RED$@"
    exit 1
}

yesno() {
    while :; do
        log-nn "$BLUE$@""? [y/n]"
        read -n1 ans
        printf "\n"
        if [ "$ans" == "y" ]; then
            return 0;
        elif [ "$ans" == "n" ]; then
            return 1;
        else
            log "$YELLOW""Unknown '$ans'"
        fi
    done
}

filenotfound() {
        fatal "$1 could not be found. Make sure to run script in its own directory"
}

showfile() {
    if [ ! -f "$1" ]; then
        filenotfound "$1"
    else
        less "$1"
    fi
}

safecat() {
    if [ ! -f "$1" ]; then
        filenotfound "$1"
    else
        cat "$1"
    fi
}

ask() {
    log-nn "$BLUE""$@: "
    read ans
}

ask-secure() {
	log-nn "$BLUE""$@: "
	read -s ans
}

#if [[ $EUID -ne 0 ]]; then
#    fatal "Script must be run as root"
#fi

yesno "Disk partitioned and partitions formatted"
if [ "$ans" == "n" ]; then
    log "Showing partitioning help"
    showfile partition-help.txt
    fatal "The disk must be partitioned"
fi

ask "Hostname"
HOSTNAME="$ans"
ask "Main username"
USERNAME="$ans"
ask-secure "Root and user password"
ROOTPASSWORD="$ans"
USERPASSWORD="$ans"
ask "Partition for root filesystem"
ROOTFS_PART="$ans"
ask "Partition for home filesystem"
HOMEFS_PART="$ans"
ask "EFI partition"
EFI_PART="$ans"
ask "Main disk /dev/ file ( no number )"
DISK_DEVFILE="$ans"

log "Everything should be automatic from here!"
sleep 2
set -e

log "Mounting partitions..."
mkdir /mnt
mount "$ROOTFS_PART" /mnt
mkdir /mnt/home
mount "$HOMEFS_PART" /mnt/home
mkdir /boot
mount "$EFI_PART" /boot

log "Getting initial packages..."
PCKGS=""
while IFS='' read -r line || [[ -n "$line" ]]; do
    PCKGS= "$PCKGS $line"
done < "$1"

log "Pacstrapping..."
pacstrap /mnt base "$PCKGS"

log "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

log "Changing root..."
arch-chroot /mnt

log "Updating package database..."
pacman -Syyu

log "Setting time zone..."
ln -sf /usr/share/zoneinfo/US/Pacific /etc/localtime

log "Updating hardware clock..."
hwclock --systohc

log "Setting locale..."
cp locale.gen /etc/locale.gen
locale-gen
printf "LANG=en_US.UTF-8" > /etc/locale.conf

log "Setting hostname..."
printf "$HOSTNAME" > /etc/hostname
printf "127.0.0.1   localhost\n" > /etc/hosts
printf "::1     localhost\n" >> /etc/hosts
printf "127.0.1.1   $HOSTNAME.localdomain  $HOSTNAME\n" >> /etc/hosts

log "Setting root password..."
printf "$ROOTPASSWORD\n" | passwd --stdin

log "Installing grub package..."
pacman -S grub

log "Setting up user..."
useradd -m -g wheel -s /bin/bash "$USERNAME"
usermod -a -G wheel "$USERNAME"
mkdir -p /home/"$USERNAME"
chown "$name":wheel /home/"$USERNAME"
printf "$USERPASSWORD\n" | passwd "$USERNAME" --stdin

log "$GREEN""Finished installing! Remember to run grub-install based on the current config before rebooting"

exit 0
