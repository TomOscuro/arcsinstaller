#!/bin/sh

### After installing the base system, login with your unelevated user acc, and run this script.
### !!!RUN THIS SCRIPT FROM YOUR BACKUP DIRECTORY!!!

# >>Restore backup dotfiles
RESTOREDIR=$PWD
sudo cp -rt /etc/ etc/bash.bashrc 
cp -rt $HOME/ home_files/* docs/ backup/
. /etc/bash.bashrc
. $HOME/.bashrc
echo "Dotfiles restored."
# In case i get in trouble...
sudo chown -R $USER:$USER $HOME/*

# >>Install the usual programs
sudo pacman -Syu
sudo pacman -S --noconfirm $(cat pkglist)
mkdir $HOME/.yay && cd $HOME/.yay
git clone https://aur.archlinux.org/yay.git
cd yay && makepkg -si
yay -S brave-bin tor-browser spotify viber 

# >>Enable firewall
sudo ufw enable 80/tcp
sudo ufw enable 443/tcp
sudo systemctl enable --now ufw

# >>Setup and enable zram
while true; do
read -p "Config and activate zram? (y/n) " ZRAM
case $ZRAM in
  [yY] )
    sudo echo "zram" > /etc/modules-load.d/zram.conf;
    read -p "Size of your RAM in Gigabytes? (eg. 8)" RAM;
    RAM=$(($RAM*1024/2));
    sudo echo -e "ACTION==\"add\", KERNEL==\"zram0\", ATTR{comp_algorithm}=\"zstd\", ATTR{disksize}=\"${RAM}M\", RUN=\"/usr/bin/mkswap -U clear /dev/%k\", TAG+=\"systemd\"" > /etc/udev/rules.d/99-zram.rules;
    sudo echo "/dev/zram0 none swap defaults,pri=100 0 0" >> /etc/fstab;
    echo "Zram setup done.'\n'Check it out by using the  $YELLOW swapon -s $NOCOLOR  or  $YELLOW zramctl  $NOCOLOR command after reboot.";
    break;;
  [nN] ) 
    echo "Zram setup skipped...";
    break;;
  * ) echo "Invalid response, type Y or N ";;
esac
done

# >>Setup and config openvpn
while true; do
read -p "Config VPN? (y/n) " VPN
case $VPN in
  [yY] )  
    sudo pacman -S --noconfirm openvpn;
    yay -S openvpn-update-systemd-resolved networkmanager-openvpn;
    sudo systemctl enable --now systemd-resolved;
    sudo cp -rt /etc/openvpn/ $RESTOREDIR/etc/openvpn/*; 
    echo "VPN has been configured"; 
    break;;
  [nN] ) 
    echo "No VPN config this time."; 
    break;;
  * ) echo "Invalid response, type Y or N ";;
esac
done
echo "Done setting up OpenVPN."

# >>NFS FSTAB entry
sudo echo -e "# NFS drive
192.168.0.52:/srv/nfs/ /mnt/nfs/ nfs defaults,noatime 0 0
" >> /etc/fstab

# >>Done
cd $HOME
printf "$GREEN
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
|               ALL DONE               | 
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$NOCOLOR"