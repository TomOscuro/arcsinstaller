#!/bin/bash

### After manually setting up your internet access ###
# Easier if you have cable connection. 

timedatectl set-ntp true > /dev/null 2>&1

# >>Partitioning drive
read -p "Input your hard drive to start formatting (for example: /dev/sda) :" HDD
#echo 'label: gpt' | sfdisk $HDD
echo -e '
,512M,C12A7328-F81F-11D2-BA4B-00A0C93EC93B\n
,8G,0657FD6D-A4AB-43C4-84E5-0933C84B4F4F\n
,+,0FC63DAF-8483-4772-8E79-3D69D8477DE4\n
' | sfdisk $HDD

# >>Format and mount drives
EFIPART=${HDD}1
SWAPPART=${HDD}2
ROOTPART=${HDD}3
mkfs.fat -F32 $EFIPART
mkswap $SWAPPART
cryptsetup luksFormat -v -y $ROOTPART
cryptsetup open $ROOTPART cryptroot
mkfs.ext4 /dev/mapper/cryptroot
mount /dev/mapper/cryptroot /mnt
mount --mkdir $EFIPART /mnt/boot

# >>Install packages
pacstrap -K /mnt base linux linux-firmware efibootmgr grub os-prober networkmanager sudo terminus-font
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt