#!/bin/bash
echo "LUbuntu handy Packages automation "

BASICAPPS="firefox thunderbird vlc pidgin mumble gimp audacity audacious libreoffice lyx synaptic catfish usb-creator-gtk vino xtightvncviewer baobab gcalctool xbacklight brasero smartmontools"
GRAPHICS="hugin" # autopano-sift"
MOREAPPS="glabels freemind gtg gnotime gtk-recordmydesktop units qrencode lm-sensors" #firestarter
COMPATIBILITY="wine winetricks dosbox samba system-config-samba chntpw"
ADVLIBS="sysv-rc-conf festival imagemagick numlockx gxmessage libnotify-bin htop gtkperf traceroute"
CODECS="ubuntu-restricted-extras pavucontrol beep   mplayer smplayer " #ffmpeg avconv
SECURITY="vidalia tor"

sudo apt-get install $BASICAPPS $MOREAPPS $ADVLIBS $COMPATIBILITY $ADVLIBS $CODECS $GRAPHICS         
 

#DVD Playback maybe ?
#sudo apt-get install libdvdread4
#sudo /usr/share/doc/libdvdread4/install-css.sh

#esddsp festival palia
echo "Installation Complete" |  festival --tts

#sudo echo "resample-method = trivial" >> /etc/pulse/daemon.conf
#sudo echo "default-sample-rate=48000" >> /etc/pulse/daemon.conf
#sudo echo "default-fragments = 14" >> /etc/pulse/daemon.conf
#sudo echo "default-fragment-size-msec = 16" >> /etc/pulse/daemon.conf
#sudo echo "frequency=48000" >> /etc/openal/alsoft.conf

if cat /etc/xdg/lxsession/Lubuntu/autostart | grep -q "setxkbmap"
then
   echo "Language settings seem to be ok!" 
  #exit 0
else
   echo "Language Settings dont seem to exist , including English/Greek , interchangable with alt-shift  .." 
   sudo sh -c 'echo "@setxkbmap -option grp:switch,grp:alt_shift_toggle,grp_led:scroll us,gr" >>/etc/xdg/lxsession/Lubuntu/autostart' 
fi


if cat /etc/sysctl.conf | grep -q "vm.swappiness"
then
   echo "Swappiness seems to be set-up ok!" 
  #exit 0
else
   echo "Setting Swapiness to 10! .." 
   sudo sh -c 'echo "vm.swappiness = 10" >>/etc/sysctl.conf' 
   sudo sysctl vm.swappiness=10
   sudo swapoff -a
   sudo swapon -a
fi




if [ -f ~/.config/autostart/autostart.desktop ]
then 
 echo "Found per-user autostart shortcut"
else 
 echo "Generating new per-user autostart shortcut"
 echo "[Desktop Entry]" > ~/.config/autostart/autostart.desktop
 echo "Type=Application" >> ~/.config/autostart/autostart.desktop
 echo "Name=MyThings" >> ~/.config/autostart/autostart.desktop

 ORIG_DIR=`pwd`
 cd ~
 USER_DIR=`pwd`
 echo "Exec=$USER_DIR/.autostart.sh" >> ~/.config/autostart/autostart.desktop
 cd $ORIG_DIR 
 chmod +x ~/.config/autostart/autostart.desktop
fi

if [ -f ~/.autostart.sh ]
then 
 echo "Found per-user autostart bash script"
else 
 echo "Generating new per-user autostart bash script"
 echo "#!/bin/bash" > ~/.autostart.sh
 echo "setxkbmap -option grp:switch,grp:alt_shift_toggle,grp_led:scroll us,gr" >> ~/.autostart.sh 
 echo "nm-applet&" >> ~/.autostart.sh 
 echo "numlockx on&" >> ~/.autostart.sh 
 echo "pidgin&" >> ~/.autostart.sh 
 echo "thunderbird&" >> ~/.autostart.sh 
 echo "firefox&" >> ~/.autostart.sh 
 echo "mumble&" >> ~/.autostart.sh 
 echo "audacious&" >> ~/.autostart.sh 
 echo "exit 0" >> ~/.autostart.sh 
 chmod +x ~/.autostart.sh 
fi

#maybe add to /etc/fstab  :     tmpfs /tmp tmpfs defaults,noexec,nosuid 0 0

#maybe add to /etc/fstab  :      tmpfs     /home/<user>/.mozilla/firefox/default/Cache tmpfs mode=1777,noatime 0 0 

sudo apt-get remove abiword


echo "Disable Apport maybe ? :P"
sudo service apport stop
gksu leafpad /etc/default/apport


#Check SSD partition for correct alignment , should return 0 
#sudo blockdev --getalignoff /dev/sda1 

#Check SSD for trim support
sudo hdparm -I /dev/sda |grep TRIM
sudo hdparm -I /dev/sdb |grep TRIM


#TODO add to /etc/fstab : noatime,nodiratime,discard,errors=remount-ro
#UUID=e3c59fb6-436d-4a42-84d4-9dc99daea30b /               ext4    noatime,nodiratime,discard,errors=remount-ro 0   



echo "Configuration Complete" |  festival --tts



# sensors-applet
exit 0
