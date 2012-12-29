#!/bin/bash
echo "LUbuntu handy Packages automation "

sudo apt-add-repository ppa:xorg-edgers/ppa
sudo apt-add-repository ppa:ubuntu-x-swat/x-updates
sudo apt-get update


BASICAPPS="firefox thunderbird vlc pidgin mumble gimp audacity audacious libreoffice synaptic catfish usb-creator-gtk vino xtightvncviewer baobab"
MOREAPPS="glabels freemind gtg gnotime gtk-recordmydesktop units firestarter qrencode"
COMPATIBILITY="wine winetricks dosbox samba system-config-samba chntpw"
ADVLIBS="sysv-rc-conf xbacklight festival imagemagick numlockx gxmessage libnotify-bin htop gtkperf traceroute"
CODECS="ubuntu-restricted-extras  libdvdread4 pavucontrol beep ffmpeg  mplayer smplayer p7zip-full"

sudo apt-get install $BASICAPPS $MOREAPPS $ADVLIBS $COMPATIBILITY $ADVLIBS $CODECS         


#esddsp festival palia
echo "Installation Complete" |  festival --tts

sudo /usr/share/doc/libdvdread4/install-css.sh

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

sudo apt-get remove abiword ace-of-penguins

echo "Config