#!/bin/bash

set -e

cd /root/

log "Updating package database..."
pacman --noconfirm -Syyu

log "Getting initial packages..."
while IFS='' read -r line || [[ -n "$line" ]]; do
	if [ -z "$PCKGS" ]; then
		export PCKGS="$line"
	else
		PCKGS="$PCKGS $line"
	fi
done < "initial-packages"

log "Packages: $PCKGS"
log "Installing initial packages..."
pacman --noconfirm -S $PCKGS

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
printf "root:$ROOTPASSWORD" | chpasswd

log "Installing grub package..."
pacman -S --noconfirm grub

log "Setting up user..."
#useradd -m -g wheel -s /bin/bash "$USERNAME"
#usermod -a -G wheel "$USERNAME"
#mkdir -p /home/"$USERNAME"
#chown "$name":wheel /home/"$USERNAME"
useradd --create-home "$USERNAME"
usermod -a -G wheel "$USERNAME"
printf "$USERNAME:$USERPASSWORD" | chpasswd

log "Giving user easy sudo for installing yay..."
printf "%%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

log "Copying over yay install script..."
cp yayinstall.sh /home/"$USERNAME"

log "Installing yay..."
sudo -u "$USERNAME" /home/"$USERNAME"/yayinstall.sh

log "Making sudo require password for user..."
sed -i '$ d' /etc/sudoers
printf "%%wheel ALL=(ALL) ALL" >> /etc/sudoers

log "$GREEN""Finished installing! Remember to run grub-install based on the current config before rebooting"

exit 0
