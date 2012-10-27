#!/bin/bash
echo "LUbuntu handy Packages automation "

BASICAPPS="firefox thunderbird vlc pidgin mumble gimp audacity audacious libreoffice synaptic catfish usb-creator-gtk lubuntu vino xtightvncviewer baobab"
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


echo "Configuration Complete" |  festival --tts

# sensors-applet
exit 0
