#!/bin/bash

# PLEASE RUN THIS SCRIPT AS ROOT!!

# Setting system clock to hardware time
hwclock --systohc

# Setting the locale
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf

# Add universe repository support
echo "[universe]" >> /etc/pacman.conf
echo "Server = https://universe.artixlinux.org/$arch" >> /etc/pacman.conf
echo "Server = https://mirror1.artixlinux.org/universe/$arch" >> /etc/pacman.conf
echo "Server = https://mirror.pascalpuffke.de/artix-universe/$arch" >> /etc/pacman.conf
echo "Server = https://artixlinux.qontinuum.space/artixlinux/universe/os/$arch" >> /etc/pacman.conf
echo "Server = https://mirror1.cl.netactuate.com/artix/universe/$arch" >> /etc/pacman.conf
echo "Server = https://ftp.crifo.org/artix-universe/" >> /etc/pacman.conf

# Installs Optional Packages
printf "\nPlease enter any optional packages that you wish to install."
printf "\nNote that no Window Managers's Desktops or Desktop Managers"
printf "\nare installed by default. Additionally, no web browsers or"
printf "\nuser-specific software is installed by default."
printf "\n\nSeperate all packages with a space"
printf "\nPackages: "
read optPack

# Setting the hostname
printf "Type a name for your machine: " >&2
read hostname
echo $hostname > /etc/hostname

# Installing the Bootloader
grub-install --recheck $drv
grub-mkconfig -o /boot/grub/grub.cfg

# Setting up Root password
passwd

# Creating a new user and setting up his/her password
printf "Type the name of the user to be created: " >&2
read usr
useradd -mG wheel $usr
passwd $usr

# Granting users of the group wheel root shell access
sed -i "s/\# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g" /etc/sudoers
echo "permit :wheel" > /etc/doas.conf

# Adding entries to the /etc/hosts file
echo "127.0.0.1        localhost" >> /etc/hosts
echo "::1              localhost" >> /etc/hosts
echo "127.0.1.1        $hostname.localdomain  $hostname" >> /etc/hosts

# Sets hostname
echo hostname=$hostname >> /etc/conf.d/hostname


# Actually install optional packages:
pacman -Syyuu pulseaudio pavucontrol $optPack

# EOF
