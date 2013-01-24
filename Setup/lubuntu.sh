#!/bin/bash
echo "LUbuntu handy Packages automation "

BASICAPPS="firefox thunderbird vlc pidgin mumble gimp audacity audacious libreoffice synaptic catfish usb-creator-gtk vino xtightvncviewer baobab gcalctool"
MOREAPPS="glabels freemind gtg gnotime gtk-recordmydesktop units firestarter qrencode"
COMPATIBILITY="wine winetricks dosbox samba system-config-samba chntpw"
ADVLIBS="sysv-rc-conf festival imagemagick numlockx gxmessage libnotify-bin htop gtkperf traceroute"
CODECS="ubuntu-restricted-extras pavucontrol beep ffmpeg  mplayer smplayer"

sudo apt-get install $BASICAPPS $MOREAPPS $ADVLIBS $COMPATIBILITY $ADVLIBS $CODECS         


#esddsp festival palia
echo "Installation Complete" |  festival --tts

#sudo echo "default-sample-rate=48000" >> /etc/pulse/daemon.conf
#sudo echo "frequency=48000" >> /etc/openal/alsoft.conf

if cat /etc/xdg/lxsession/Lubuntu/autostart | grep -q "setxkbmap"
then
   echo "Language settings seem to be ok!" 
  exit 0
else
   echo "Language Settings dont seem to exist , including English/Greek , interchangable with alt-shift  .." 
   sudo sh -c 'echo "@setxkbmap -option grp:switch,grp:alt_shift_toggle,grp_led:scroll us,gr" >>/etc/xdg/lxsession/Lubuntu/autostart' 
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
 echo "pidgin&" >> ~/.autostart.sh 
 echo "thunderbird&" >> ~/.autostart.sh 
 echo "firefox&" >> ~/.autostart.sh 
 echo "mumble&" >> ~/.autostart.sh 
 echo "audacious&" >> ~/.autostart.sh 
 echo "exit 0" >> ~/.autostart.sh 
 chmod +x ~/.autostart.sh 
fi


sudo apt-get remove abiword


echo "Disable Apport maybe ? :P"
sudo service apport stop
gksu gedit /etc/default/apport


echo "Configuration Complete" |  festival --tts



# sensors-applet
exit 0
