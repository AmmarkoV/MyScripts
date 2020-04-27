#!/bin/bash


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "LUbuntu handy Packages automation "

sudo apt-get install gksu

sudo add-apt-repository ppa:graphics-drivers/ppa
sudo apt-get update


#Go to latest kernel..
#sudo apt-get install --install-recommends linux-generic-hwe-18.04 xserver-xorg-hwe-18.04 

#-----------------------------------------------------------------------------------------------------------------------
BASICAPPS="firefox thunderbird vlc pidgin mumble libreoffice myspell-el-gr  synaptic catfish usb-creator-gtk remmina baobab xbacklight brasero  " #gcalctool hunspell-el lyx vino xtightvncviewer 
GRAPHICS="hugin gimp luminance-hdr darktable" # autopano-sift"
AUDIO="mixxx audacity audacious " 
MOREAPPS=" gtg gtk-recordmydesktop units qrencode lm-sensors gnome-system-monitor" #glabels freemind firestarter gnotime
COMPATIBILITY="samba system-config-samba chntpw" #wine winetricks dosbox 
SYSTEM="smartmontools iotop iftop iperf ifmetric htop gtkperf traceroute powertop x11vnc net-tools" #macchanger-gtk  sysv-rc-conf 
SCREENSAVERS="xscreensaver xscreensaver-data xscreensaver-data-extra  xscreensaver-gl xscreensaver-gl-extra"
ADVLIBS="festival imagemagick numlockx gxmessage libnotify-bin htop gtkperf traceroute powertop x11vnc" #macchanger-gtk  sysv-rc-conf 
CODECS="ubuntu-restricted-extras pavucontrol beep ffmpeg mplayer smplayer " #ffmpeg avconv
SECURITY="network-manager-openvpn network-manager-openvpn-gnome" #vidalia tor 
#-----------------------------------------------------------------------------------------------------------------------
sudo apt-get install $BASICAPPS $MOREAPPS $ADVLIBS $COMPATIBILITY $SYSTEM $SCREENSAVERS $ADVLIBS $AUDIO $CODECS $GRAPHICS $SECURITY         
   


#DVD Playback maybe ?
sudo apt-get install libdvdread4
sudo /usr/share/doc/libdvdread4/install-css.sh

#dbus is neede for gedit?
#sudo apt-get install --reinstall dbus dbus-x11

#sudo update-alternatives --config x86_64-linux-gnu_gl_conf

#esddsp festival palia
echo "Installation Complete" |  festival --tts

#Tell pulse audio not to stutter
if cat /etc/pulse/daemon.conf | grep -q "ammar"
then
   echo "PulseAudio settings seem to be ok!" 
else
 sudo echo "#ammar's lower stutter settings" >> /etc/pulse/daemon.conf
 sudo echo "resample-method = trivial" >> /etc/pulse/daemon.conf
 #sudo echo "default-sample-rate=48000" >> /etc/pulse/daemon.conf
 sudo echo "default-sample-rate=44100" >> /etc/pulse/daemon.conf
 sudo echo "default-fragments = 14" >> /etc/pulse/daemon.conf
 sudo echo "default-fragment-size-msec = 16" >> /etc/pulse/daemon.conf
 #sudo echo "frequency=48000" >> /etc/openal/alsoft.conf
 #sudo echo "frequency=44100" >> /etc/openal/alsoft.conf
fi


#Tweak TCP congestion
if cat /etc/sysctl.d/10-custom-kernel-bbr.conf | grep -q "tcp_congestion_control=bbr"
then
   echo "TCP BBR congestion control settings seem to be set!" 
else
 echo "Setting up TCP BBR congestion control" 
 sudo echo "net.core.default_qdisc=fq" >> /etc/sysctl.d/10-custom-kernel-bbr.conf
 sudo echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.d/10-custom-kernel-bbr.conf
 sudo sysctl --system
fi
 

#Setup languages on login..
if cat /etc/xdg/lxsession/Lubuntu/autostart | grep -q "setxkbmap"
then
   echo "Language settings seem to be ok!" 
else
   echo "Language Settings dont seem to exist , including English/Greek , interchangable with alt-shift  .." 
   sudo sh -c 'echo "@setxkbmap -option grp:switch,grp:alt_shift_toggle,grp_led:scroll us,gr" >>/etc/xdg/lxsession/Lubuntu/autostart' 
fi


MEM=`awk '/Mem:/ {print $2}' <(free)`
if (( $MEM > 8000000 )) 
then
echo "We appear to have a lot of RAM ( $MEM bytes ) optimizing "
if cat /etc/sysctl.conf | grep -q "vm.swappiness"
then
   echo "Memory usage optimizations seems to be already set-up.." 
else
   echo "Optimizing memory usage for better disk access! .." 
   sudo sysctl vm.swappiness=10
   sudo sysctl vm.dirty_ratio=99
   sudo sysctl vm.dirty_background_ratio=50
   sudo sysctl vm.vfs_cache_pressure=10 

   sudo sh -c 'echo "vm.swappiness = 10" >>/etc/sysctl.conf' 
   sudo sh -c 'echo "vm.dirty_ratio = 99" >>/etc/sysctl.conf' 
   sudo sh -c 'echo "vm.dirty_background_ratio = 50" >>/etc/sysctl.conf' 
   sudo sh -c 'echo "vm.vfs_cache_pressure= 10" >>/etc/sysctl.conf'  

   sudo swapoff -a
   sudo swapon -a
fi 
fi

#if cat /etc/fstab | grep -q "/ramfs"
#then
#   echo "RAM fs seems to be set up ok!" 
#else
#   echo "Adding some ramfs partitions.." 
#   sudo sh -c 'echo "none    /ramfs    ramfs   nodev,nosuid,noexec,nodiratime,size=256M    0   0" >>/etc/fstab' 
#   sudo sh -c 'echo "none    /tmp    ramfs   nodev,nosuid,noexec,nodiratime,size=256M    0   0" >>/etc/fstab' 
#   sudo mount -t ramfs -o nodev,nosuid,noexec,nodiratime,size=256M none /ramfs
#fi




if [ -d ~/.config/autostart ] 
   then
     echo "Autostart Directory exists"
   else
     echo "Autostart Directory Does not exist"
     mkdir ~/.config/autostart
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
 echo "xset r on" >> ~/.autostart.sh  
 echo "#xscreensaver -nosplash&" >> ~/.autostart.sh
 echo "nm-applet&" >> ~/.autostart.sh 
 echo "numlockx on&" >> ~/.autostart.sh 
 echo "pidgin&" >> ~/.autostart.sh 
 echo "thunderbird&" >> ~/.autostart.sh 
 echo "firefox&" >> ~/.autostart.sh 
 echo "mumble&" >> ~/.autostart.sh 
 echo "audacious&" >> ~/.autostart.sh
 echo "plasmawindowed org.kde.kdeconnect --statusnotifier" >> ~/.autostart.sh
 echo "#x11vnc -nap -wait 50 -noxdamage -passwd ammar -display :0 -forever -o ~/x11vnc.log -bg" >> ~/.autostart.sh 
 echo "#ssh -L 8080:192.168.1.1:80 ammar.gr -c arcfour -p 2222" >> ~/.autostart.sh


 echo "sleep 38" >> ~/.autostart.sh
 echo "xdotool key \"Ctrl+Alt+Right\" " >> ~/.autostart.sh
 echo "thunderbird&" >> ~/.autostart.sh
 echo "sleep 30" >> ~/.autostart.sh
 echo "xdotool key \"Ctrl+Alt+Left\" " >> ~/.autostart.sh



 echo "exit 0" >> ~/.autostart.sh 
 chmod +x ~/.autostart.sh 
fi




#Create shared directory
if [ -f /etc/samba/smb.conf ]
then 
 if cat /etc/samba/smb.conf | grep -q "[SHARED]"
then
   echo "SAMBA seems to be already set-up.." 
else
 mkdir ~/SHARED
 USER=`whoami`
 echo "[SHARED]"  >> /etc/samba/smb.conf
 echo "path = /home/$USER/SHARED"  >> /etc/samba/smb.conf
 echo "writable = yes"  >> /etc/samba/smb.conf
 echo "guest ok = yes"  >> /etc/samba/smb.conf
 echo "guest only = yes"  >> /etc/samba/smb.conf
 echo "read only = no"  >> /etc/samba/smb.conf
 echo "create mode = 0777"  >> /etc/samba/smb.conf
 echo "directory mode = 0777"  >> /etc/samba/smb.conf
 echo "force user = nobody"  >> /etc/samba/smb.conf
 sudo systemctl restart smbd
 fi
fi




#maybe add to /etc/fstab  :     tmpfs /tmp tmpfs defaults,noexec,nosuid 0 0
#maybe add to /etc/fstab  :      tmpfs     /home/<user>/.mozilla/firefox/default/Cache tmpfs mode=1777,noatime 0 0 

echo "Removing applications that we don't need.."
sudo apt-get remove abiword gnumeric



echo "Saving you from Apport spam"
sudo service apport stop
sudo echo "# set this to 0 to disable apport, or to 1 to enable it" > /etc/default/apport
sudo echo "# ammar settings dont like it" >> /etc/default/apport
sudo echo "#Can be temporarily overwritten using : sudo service apport start force_start=1" >> /etc/default/apport
sudo echo "enabled=0" >> /etc/default/apport
#echo "Disable Apport maybe ? :P"
#gksu leafpad /etc/default/apport


#For Lubuntu 20.04 + PDF export is broken in Libreoffice except if 
#TODO add this automatically ? 
#LXQt settings -> Click Environment (Advanced) -> Click Add 
#    Double click the empty variable name, and type SAL_VCL_QT5_USE_CAIRO, press Enter
#    Double click the Value field, and type true, press Enter
#    Click Close
#    Click OK to the dialog box 
#SAL_VCL_QT5_USE_CAIRO=true
#is added to environment

#Check SSD partition for correct alignment , should return 0 
#sudo blockdev --getalignoff /dev/sda1 

#Check SSD for trim support
sudo hdparm -I /dev/sda |grep TRIM
sudo hdparm -I /dev/sdb |grep TRIM


#TODO add to /etc/fstab : noatime,nodiratime,discard,errors=remount-ro
#UUID=e3c59fb6-436d-4a42-84d4-9dc99daea30b /               ext4    noatime,nodiratime,discard,errors=remount-ro 0   

#Disable intel powerclamp
sudo sh -c 'echo "blacklist intel_powerclamp" > /etc/modprobe.d/disable-powerclamp.conf'

cd /usr/share/lubuntu/wallpapers/ 
sudo wget https://raw.githubusercontent.com/AmmarkoV/MyScripts/master/Multimedia/startup.png 
sudo mv /usr/share/lubuntu/wallpapers/lubuntu-default-wallpaper.png /usr/share/lubuntu/wallpapers/lubuntu-default-wallpaperOLD.png
sudo ln -s  /usr/share/lubuntu/wallpapers/startup.png /usr/share/lubuntu/wallpapers/lubuntu-default-wallpaper.png

firefox https://addons.mozilla.org/en-US/firefox/addon/tab-list/&
firefox https://addons.mozilla.org/en-US/firefox/addon/os-x-yosemite/&
firefox https://addons.mozilla.org/en-US/firefox/addon/noscript/&
firefox https://addons.mozilla.org/en-US/firefox/addon/adblock-plus/?src=ss&
#firefox https://addons.mozilla.org/en-US/firefox/addon/video-downloadhelper/&
#firefox https://addons.mozilla.org/en-US/firefox/addon/download-youtube/&

#Hit about:config
#set browser.sessionhistory.max_entries 10
#set browser.cache.memory.enable 2048


echo "Using a nice selection of XScreensavers"
cd "$DIR"
cp xscreensaver ~/.xscreensaver

#----------------------------------------------------------
if [ -f ~/.lock.sh ]
then 
 echo "Found per-user lock bash script"
else 
 echo "Generating new per-user lock bash script"
 echo "#!/bin/bash" > ~/.lock.sh 
 echo "NUMBEROFSCREENSAVERDAEMONSRUNNING=\`ps -A | grep xscreensaver | wc -l\`" > ~/.lock.sh
 echo "if [ "$NUMBEROFSCREENSAVERDAEMONSRUNNING" -eq \"0\" ]; then" > ~/.lock.sh
 echo "     echo \"XScreensaver not running, starting it up\" " > ~/.lock.sh
 echo "     xscreensaver -nosplash&" > ~/.lock.sh
 echo "     sleep 1" > ~/.lock.sh
 echo "fi" > ~/.lock.sh
 echo "xscreensaver-command -lock" > ~/.lock.sh
 echo "exit 0" >> ~/.lock.sh 
 chmod +x ~/.lock.sh 
fi
#----------------------------------------------------------
#Create Lock Shortcut
if [ -f ~/Desktop/lock.desktop ]
then 
 if cat ~/Desktop/lock.desktop | grep -q "NUMBEROFSCREENSAVERDAEMONSRUNNING"
then
   echo "XScreensaver seems to be already set-up.." 
else
 echo "[Desktop Entry]" > ~/Desktop/lock.desktop
 echo "Type=Application" >> ~/Desktop/lock.desktop
 echo "Name=Lock" >> ~/Desktop/lock.desktop

 ORIG_DIR=`pwd`
 cd ~
 USER_DIR=`pwd`
 echo "Exec=$USER_DIR/.lock.sh" >> ~/Desktop/lock.desktop
 fi
fi
#----------------------------------------------------------


echo "Configuration Complete" |  festival --tts




# sensors-applet
exit 0
