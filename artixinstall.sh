#!/bin/bash

## READ ME ##
# - Please make sure that you run this script as root.
# - Ensure that you have a working internet connection before running.
# - If you need to change your keyboard layout, this is the time to do it.
# - Ensure that the drive you are installing to has been completely wiped.
# - You can use fdisk to delete drive partitions, and swapoff to disable
#   any swap partitions from previous installations.

# List available drives for installation
lsblk

# Select Drive
printf "\nType the path of your drive [eg. /dev/sda]" >&2
read drive

# Partition Drive
echo 'start=2048, type=83, bootable' | sfdisk $drive

root="${drive}1"

# Format and Mount drive
mkfs.ext4 -L root $root
mount $root /mnt


# Choose the processor type [to install correct microcode]
printf "\nWhat processor does your system use?"
for i in amd intel
do
  printf "\n$i"
done

printf "\nAnswer: " >&2
read cpu

if [[ ($cpu = "intel") ]]; then
  ucode="intel-ucode"
elif [[ ($cpu = "amd") ]]; then
  ucode="amd-ucode"
fi

printf '\n'

# Installs packages necessary for any artix/openrc desktop install
basestrap /mnt base base-devel openrc elogind-openrc linux-hardened \
linux-firmware "$ucode" sudo doas man man-pages vim groff wget git \
dialog dhcpcd dhcpcd-openrc gnupg openssh libx11 xorg-server \
xorg-xinit libxrandr libxft xorg-xrdb xorg-xrandr xf86-video-intel \
xf86-video-nouveau bash networkmanager-openrc wpa_supplicant

# Generating the fstab
fstabgen -U /mnt >> /mnt/etc/fstab
$edit /mnt/etc/fstab

# Copying the artixconfig.sh script and making it executable
cp ./artixconfig.sh /mnt/artixconfig.sh
chmod +x /mnt/artixconfig.sh

# Export Variables for future use
export drive
export root


# Entering in the chroot environment
artix-chroot /mnt ./artixconfig.sh 

# Then, the live system will umount the drive on the /mnt directory and reboot
# the computer
umount -R /mnt

# Prompting if the user wants to reboot the computer
printf "Do you want to restart the computer? (y/n): " >&2
read ans

if [[ ($ans = "y" || $ans = "Y") ]]; then
    reboot
    fi


# EOF
