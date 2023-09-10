#!/bin/bash

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
pacman -Syu --noconfirm

# >>Locale
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock -w
echo "LANG=en_US.UTF-8" > vconsole.conf
echo "FONT=ter-116n" >> /etc/vconsole.conf
echo "KEYMAP=hu" > /etc/locale.conf
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen

# >>Networking
read -p "Choose a hostname: " HOSTNAME
echo "$HOSTNAME" > /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1 localhost" >> /etc/hosts
echo "127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts
systemctl enable NetworkManager

# >>Initramfs
# Adding "encrypt" to HOOKS in /etc/mkinitcpio.conf
sed -i "/HOOKS/c HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont block encrypt filesystems fsck)" /etc/mkinitcpio.conf
mkinitcpio -p linux

# >>GRUB2 bootloader
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arcs
# adding UUID for cryptdevice to /etc/default/grub
UUID=$(sudo blkid | grep /dev/sdb3 | awk -F\" '{print $2}')
LINE="GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=${UUID}:cryptroot root=/dev/mapper/cryptroot\""
sed -i "/GRUB_CMDLINE_LINUX=/c ${LINE}" /etc/default/grub
# make grub cfg
grub-mkconfig -o /boot/grub/grub.cfg

# >>Users & passwords
clear && echo "Password for ROOT:"
passwd
clear && echo "Creating a USER:"
read -p "username: " NEWUSERNAME
useradd -mG wheel $NEWUSERNAME
passwd $NEWUSERNAME

# >>Sudo
bash -c 'echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers.d/custom'
visudo -cf /etc/sudoers.d/custom

