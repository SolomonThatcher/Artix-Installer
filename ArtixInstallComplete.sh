#!/bin/bash

## READ ME ##
# - Please make sure that you run this script as root.
# - Ensure that you have a working internet connection before running.
# - If you need to change your keyboard layout, this is the time to do it.
# - Ensure that the drive you are installing to has been completely wiped.
# - You can use fdisk to delete drive partitions, and swapoff to disable
#   any swap partitions from previous installations.
# - [TO-DO] Re-write every step as a function

# Main function
function main {
clear
printf "###############################\n"
printf "#                             #\n"
printf "#  ARTIX INSTALLATION SCRIPT  #\n"
printf "#           MADE BY           #\n"
printf "#      SOLOMON THATCHER       #\n"
printf "#                             #\n"
printf "###############################\n\n"
disk_select
}

# Select Disk
function disk_select {
	
	# List Available drives
	lsblk
	
	# Prompt for user to input drive name
	printf "\nType the path of your desired drive [eg. /dev/sda]\n> "
	read drive
	
	# Check if user wants disk encryption
	printf "\nDo you wish to use Disk Encryption? [y/n]\n> "
	read ans
	if [[ ($ans = "y" || $ans = "Y") ]]; then

		# Ask user if they want Full or Partial Disk encryption
		# Full Disk Encryption has much slower boot-times than Partial.
		# Partial Disk Encryption does not encrypt the boot partition.
		while true; do
			printf "\nDo you want to use Full or Partial Disk encryption?"
			printf " [full/partial]\n> "
			read fullPartial
		
  		# Choose Full or Partial encryption
  		if [ "$fullPartial" = "full" ]; then
    		printf "\nDisk will be set up with Full Disk Encryption"
				#full_encrypt
  		elif [ "$fullPartial" = "partial" ]; then
				printf "\nDisk will be set up with Partial Disk Encryption"
    		#partial_encrypt
  		else
    		printf "\n!!Input not understood!!"
    		continue
  		fi
  		break
		done

	# Do not encrypt Disk
	elif [[ ($ans = "n" || $ans = "N") ]]; then
		printf "\nDisk will NOT be encrypted"
		#no_encrypt
	# Default's to No Disk encryption if input is not understood
	else
		printf "\nCould not read response, defaulting to no Disk Encryption"
		#no_encrypt
	fi

}


# Wipes selected drive
function wipe_disk {
	printf "\nAre you sure you want to continue?"
	printf "\nAll partitions on $disk will be deleted"
	printf "\nType 'yes' if you want to continue...\n> "
	read ans

	if [[ ($ans = "yes" || $ans = "YES") ]]; then
		continue
	else
		printf "\n ABORTING..."
		sleep 1
		exit 0
	fi

	printf "\nWiping Disk $drive..."
	dd bs=4096 if=/dev/urandom iflag=nocache of=$drive oflag=direct status=progress || true
	sync
	printf "\n$drive has been wiped!"
}

# Install without encryption
function no_encrypt {
	wipe_disk
	printf "\n No Encrypt"
}

## Install with partial encryption ##
function partial_encrypt {
	# Does a complete Disk wipe
	wipe_disk

	printf "\n Seting up encryption..."

	# Create the necessary disk partitions	
	parted -s $drive mklabel msdos
	parted -s -a optimal $drive mkpart "primary" "fat16" "0%" "1024MiB"
	parted -s $drive set 1 boot on
	parted -s -a optimal $drive mkpart "primary" "ext4" "1024MiB" "100%"
	parted -s $drive set 2 lvm on
	
	## Set-up Logical Volumes ##
	
	# Force Load kernel modules
	cryptsetup benchmark
	
	# Create LUKS partition
	cryptsetup --verbose --type luks1 --cipher serpent-xts-plain64 --key-size 512 --hash whirlpool --iter-time 10000 --use-random --verify-passphrase luksFormat ${drive}2
	
	# Mount LUKS partition
	cryptsetup luksOpen ${drive}2 lvm-system
	
	# Create a physical Volume
	pvcreate /dev/mapper/lvm-system
		
	# Create logical volume group "lvmSystem"
	vgcreate lvmSystem /dev/mapper/lvm-system
	
	#Prompt for swap
	printf "\n How much swap do you want? [eg. 8G]\n> "
	read swap

	# Create Logical Root and Swap volumes
	lvcreate --contiguous y --size $swap lvmSystem --name volSwap
	lvcreate --contiguous y --extents +100%FREE lvmSystem --name volRoot

	# Format the boot partition
	mkfs.fat -n BOOT ${drive}1

	# Format the swap partition
	mkswap -L SWAP /dev/lvmSystem/volSwap

	# Format the root partition
	mkfs.ext4 -L ROOT /dev/lvmSystem/volRoot
	
	# Enable the Swap partition
	swapon /dev/lvmSystem/volSwap
	
	# Mount the partitions
	mount /dev/lvmSystem/volRoot /mnt
	mkdir /mnt/boot
	mount /dev/sdX1 /mnt/boot
}


# Install with full encryption
function full_encrypt {
	wipe_disk

	printf "Setting up Full Encryption"

	# Create disk partitions
	parted -s $drive mklabel msdos
	parted -s -a optimal $drive mkpart "primary" "ext4" "0%" "100%"
	parted -s /dev/sdX set 1 boot on
	parted -s /dev/sdX set 1 lvm on
	parted -s /dev/sdX align-check optimal 1

	## Set-Up Logical Volumes ##

	# Loads Necessary kernel modules
	cryptsetup benchmark

	# Creates and formats LUKS partitions
	cryptsetup --verbose --type luks1 --cipher serpent-xts-plain64 --key-size 512 --hash whirlpool --iter-time 10000 --use-random --verify-passphrase luksFormat ${drive}1
	cryptsetup luksOpen ${drive}1 lvm-system
	
	# Create physical volumes
	pvcreate /dev/mapper/lvm-system

	# Create logical volume group
	vgcreate lvmSystem /dev/mapper/lvm-system
	
	#Prompt for swap
  printf "\n How much swap do you want? [eg. 8G]\n> "
  read swap

	# Create logical volumes for swap and boot
	lvcreate --contiguous y --size 1G lvmSystem --name volBoot
	lvcreate --contiguous y --size $swap lvmSystem --name volSwap
	lvcreate --contiguous y --extents +100%FREE lvmSystem --name volRoot

	# Create and format Boot, Swap, and Root partitions
	mkfs.fat -n BOOT /dev/lvmSystem/volBoot
	mkswap -L SWAP /dev/lvmSystem/volSwap
	mkfs.ext4 -L ROOT /dev/lvmSystem/volRoot
	swapon /dev/lvmSystem/volSwap

	# Mount newly created partitions
	mount /dev/lvmSystem/volRoot /mnt
	mkdir /mnt/boot
	mount /dev/lvmSystem/volBoot /mnt/boot
}




# [TO-DO] Replace with M00E10's disk partitioning
# Partition Drive
#echo 'start=2048, type=83, bootable' | sfdisk $drive

#root="${drive}1"

# Format and Mount drive
#mkfs.ext4 -L root $root
#mount $root /mnt


# Choose the processor type [to install correct microcode]
#printf "\nWhat processor does your system use?"
#for i in amd intel
#do
#  printf "\n$i"
#done

#printf "\nAnswer: " >&2
#read cpu

#if [[ ($cpu = "intel") ]]; then
#  ucode="intel-ucode"
#elif [[ ($cpu = "amd") ]]; then
#  ucode="amd-ucode"
#fi

#printf '\n'

# Installs packages necessary for any artix/openrc desktop install
# Feel free to change any of these packages.
#basestrap /mnt base base-devel openrc elogind-openrc linux-hardened \
#linux-firmware "$ucode" sudo doas man man-pages vim groff wget git \
#dialog dhcpcd dhcpcd-openrc gnupg openssh libx11 xorg-server \
#xorg-xinit libxrandr libxft xorg-xrdb xorg-xrandr xf86-video-intel \
#xf86-video-nouveau bash networkmanager-openrc wpa_supplicant

# Generating the fstab
#fstabgen -U /mnt >> /mnt/etc/fstab
#$edit /mnt/etc/fstab

# Copying the artixconfig.sh script and making it executable
#cp ./artixconfig.sh /mnt/artixconfig.sh
#chmod +x /mnt/artixconfig.sh

# Export Variables for future use
#export drive
#export root


# Entering in the chroot environment
#artix-chroot /mnt ./artixconfig.sh 

# Then, the live system will umount the drive on the /mnt directory and reboot
# the computer
#umount -R /mnt
#Prompting
# Prompting if the user wants to reboot the computer
#printf "Do you want to restart the computer? (y/n): " >&2
#read ans

#if [[ ($ans = "y" || $ans = "Y") ]]; then
#    reboot
#    fi

main
