#!/bin/bash

### After chrooting into /mnt ###

read -p "Input the name of drive you installed the base on (for example: /dev/sda) :" HDD

# >>Refreshing the base system
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
UUID=$(blkid | grep ${HDD}3 | awk -F\" '{print $2}')
echo $UUID
LINE="GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=${UUID}:cryptroot root=/dev/mapper/cryptroot\""
echo $LINE
sed -i "/GRUB_CMDLINE_LINUX=/c ${LINE}" /etc/default/grub
# make grub cfg
grub-mkconfig -o /boot/grub/grub.cfg

# >>Users & passwords
echo -e "\nPassword for ROOT..."
passwd
echo -e "\nCreating a USER..."
read -p "username: " NEWUSERNAME
useradd -mG wheel $NEWUSERNAME
passwd $NEWUSERNAME

# >>Sudo
bash -c 'echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers.d/custom'
visudo -cf /etc/sudoers.d/custom

echo -e "Your system is set up.\nUse CTRL+D to exit the chroot,\n'umount -R /mnt' to unmount your system,\nthen you can reboot into your new system."