#!/bin/sh

# >>Backup basic shit
cd $HOME
CURRENTDATE=`date +%Y-%m-%d-%H%M%S`
DIR="backup-$CURRENTDATE"
mkdir $DIR
echo "Backup dir created in your home dir."

# .config
mkdir -p $DIR/home_files/.config/
sudo cp -rt $DIR/home_files/.config/ .config/qtile/ .config/alacritty/ .config/picom/ .config/neofetch/ 
sudo cp -rt $DIR/home_files/ .ssh/ .xinitrc .gnupg/ keys/ wallpaper/
# openvpn config files
mkdir -p $DIR/etc
sudo cp -rt $DIR/etc/ /etc/openvpn/
# bash files
sudo cp -rt $DIR/etc/ /etc/bash.bashrc
sudo cp -rt $DIR/home_files/ .bashrc .bash_extentions .bash_aliases
# fonts
mkdir -p $DIR/home_files/.local/share/
cp -rt $DIR/home_files/.local/share/ .local/share/fonts/

echo "Your dotfiles are backed up."

# >>Copy backupscripts to backup dir
cp -rt $DIR/ projects/arcsinstaller/

# >>Documents
while true; do
read -p "$ORANGE Want to back up your docs? (y/n) $NOCOLOR" DOC
case $DOC in
  [yY]* )
    cp -rt $DIR/ docs/;  
    break;;
  [nN]* ) 
    echo "Not saving your docs this time."; 
    break;;
  * ) echo "Invalid response, type Y or N ";;
esac
done
sudo chown -R $USER:$USER $DIR/

# >>Copy the backup dir to my NFS
BKUPSRV="tom@192.168.0.52:/srv/nfs/backup/"
scp -rq $DIR $BKUPSRV
sudo rm -r $DIR && clear

# >>Done
echo -e "The whole backup is trasfered to the following location:\n$YELLOW $BKUPSRV $NOCOLOR"
printf "$GREEN
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
|             BACKUP  DONE             |
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$NOCOLOR"