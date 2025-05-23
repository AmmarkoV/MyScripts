#!/bin/bash

# This script is inteded to be run once after you perform a Lubuntu intallation
# https://lubuntu.me/downloads/
# Repositories and software comes and goes so feel free to customize this to match your preferences 


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

clear
echo "LUbuntu handy Packages automation "

sudo apt-get update

#sudo apt-get install gksu


if lspci | grep  "NVIDIA"
then
  lspci | grep  "NVIDIA"
  echo
  echo "Do you want to install NVIDIA drivers and stuff? " 
  echo
  echo -n " (Y/N)?"
  read answer
  if test "$answer" != "N" -a "$answer" != "n";
  then 
    sudo add-apt-repository ppa:graphics-drivers/ppa
    sudo apt-get update
    #Get Vulkan
    sudo apt-get install nvidia-driver-560 libglew-dev nvtop freeglut3-dev vulkan-tools vulkan-utility-libraries-de #freeglut3
    sudo chmod u+x /usr/share/screen-resolution-extra/nvidia-polkit #This needs execution for resolution saving
  fi
fi


if lsusb | grep  "Razer"
then
  lsusb | grep  "Razer"
  echo
  echo "Do you want to install Razer drivers and stuff? " 
  echo
  echo -n " (Y/N)?"
  read answer
  if test "$answer" != "N" -a "$answer" != "n";
  then 
    #Get Vulkan
    sudo apt-get install openrazer-meta
    sudo add-apt-repository ppa:polychromatic/stable
    sudo apt update
    sudo apt install polychromatic
  fi
fi


#Go to hwe kernel..
#sudo apt-get install --install-recommends linux-generic-hwe-18.04 xserver-xorg-hwe-18.04 

#-----------------------------------------------------------------------------------------------------------------------
BASICAPPS="firefox thunderbird vlc pidgin mumble libreoffice  myspell-el-gr synaptic catfish usb-creator-gtk remmina baobab xbacklight brasero aisleriot" #gcalctool hunspell-el lyx vino xtightvncviewer libreoffice-avmedia-backend-gstreamer
GRAPHICS="gimp darktable" # luminance-hdr  hugin autopano-sift"
AUDIO="mixxx audacity audacious" 
MOREAPPS="simplescreenrecorder units qrencode lm-sensors " #gtg glabels freemind firestarter gnotime gtk-recordmydesktop gnome-system-monitor
COMPATIBILITY="samba chntpw" #wine winetricks dosbox system-config-samba 
SYSTEM="smartmontools iat iotop iftop iperf ifmetric htop screen traceroute powertop x11vnc net-tools libvdpau-va-gl1 curl wget vdpauinfo neofetch chrony gddrescue ntfs-3g" #grub-customizer  macchanger-gtk  sysv-rc-conf 
#iat converts from .iso to .bin etc
SCREENSAVERS="xscreensaver xscreensaver-data xscreensaver-data-extra  xscreensaver-gl xscreensaver-gl-extra"
ADVLIBS="festival imagemagick numlockx gxmessage libnotify-bin htop  traceroute powertop x11vnc" #macchanger-gtk  sysv-rc-conf 
CODECS="ubuntu-restricted-extras pavucontrol beep ffmpeg mplayer smplayer " #ffmpeg avconv
SECURITY="network-manager-openvpn network-manager-openvpn-gnome" #vidalia tor 
DIGITALSIGNING="poppler-utils poppler-data libnss3-tools" # r8168-dkms for elina laptop with RTL ethernet
#-----------------------------------------------------------------------------------------------------------------------
sudo apt-get install $BASICAPPS $MOREAPPS $ADVLIBS $COMPATIBILITY $SYSTEM $SCREENSAVERS $ADVLIBS $AUDIO $CODECS $GRAPHICS $SECURITY $DIGITALSIGNING

datectl
#sudo chronyd -q

#Also upgrade everything else..
sudo apt-get dist-upgrade


#Extra Server Security maybe?
#sudo apt-get install fail2ban
#sudo iptables -S <- gia na dei kaneis to ban list


#DVD Playback maybe ?  :P no one uses DVD in 2021
#sudo apt-get install libdvdread4
#sudo /usr/share/doc/libdvdread4/install-css.sh

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




#Allow apt-get to update kernels without symlinks 
if cat /etc/kernel-img.conf | grep -q "do_symlinks"
then
   echo "Kernel image settings seem to be ok!" 
else
 sudo echo "do_symlinks = no"  >> /etc/kernel-img.conf
 sudo echo "no_symlinks = yes" >> /etc/kernel-img.conf
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
  
   sudo sh -c 'echo "vm.nr_hugepages=128" >>/etc/sysctl.conf'  

   sudo swapoff -a
   sudo swapon -a
fi 
fi


#Add 8GB of swap as a file in /
#sudo swapon --show
#sudo fallocate -l 8G /swapfile
#sudo chmod 600 /swapfile 
#sudo mkswap /swapfile
#sudo swapon /swapfile
#sudo swapon --show
#echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab


#if cat /etc/fstab | grep -q "/ramfs"
#then
#   echo "RAM fs seems to be set up ok!" 
#else
#   echo "Adding some ramfs partitions.." 
#   sudo sh -c 'echo "none    /ramfs    ramfs   nodev,nosuid,noexec,nodiratime,size=256M    0   0" >>/etc/fstab' 
#   sudo sh -c 'echo "none    /tmp    ramfs   nodev,nosuid,noexec,nodiratime,size=256M    0   0" >>/etc/fstab' 
#   sudo mount -t ramfs -o nodev,nosuid,noexec,nodiratime,size=256M none /ramfs
#fi


#Add a DLNA server
#sudo apt-get install minidlna
#sudo nano /etc/minidlna.conf 
#media_dir=V,/media/ammar/AmmarKriti/ammar/Videos/
#media_dir=V,/home/ammar/Videos/DVD/
#inotify=yes
#nnotify_interval=30



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




#This .autostart.sh file will be run on each session
#you can edit it at any time using nano ~/.autostart.sh
#this is software I typically use and want to automatically startup
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
 echo "firefox&" >> ~/.autostart.sh 
 echo "#mumble&" >> ~/.autostart.sh 
 echo "#audacious&" >> ~/.autostart.sh
 echo "plasmawindowed org.kde.kdeconnect --statusnotifier" >> ~/.autostart.sh
 echo "#x11vnc -nap -wait 50 -noxdamage -passwd ammar -display :0 -forever -o ~/x11vnc.log -bg" >> ~/.autostart.sh 
 echo "#ssh -L 8080:192.168.1.1:80 ammar.gr -c arcfour -p 2222" >> ~/.autostart.sh

 echo "sleep 38" >> ~/.autostart.sh
 #Go to the right workspace
 echo "xdotool key \"Ctrl+Alt+Right\" " >> ~/.autostart.sh
 echo "thunderbird&" >> ~/.autostart.sh
 echo "sleep 30" >> ~/.autostart.sh
 #Go to the left workspace
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
#sudo apt-get remove abiword gnumeric



echo "Saving you from Apport spam"
 sudo service apport stop
 sudo sh -c 'echo "# set this to 0 to disable apport, or to 1 to enable it" > /etc/default/apport' 
 sudo sh -c 'echo "# ammar settings dont like it" >> /etc/default/apport' 
 sudo sh -c 'echo "#Can be temporarily overwritten using : sudo service apport start force_start=1" >> /etc/default/apport' 
 sudo sh -c 'echo "enabled=0" >> /etc/default/apport' 
#echo "Disable Apport maybe ? :P"
#gksu leafpad /etc/default/apport



#----------------------------------------------------------
if [ -f /etc/sudo.conf ]
then 
 echo "Found already set sudo.conf so not modifying it.."
else 
 echo "Adding ssh-askpass as a utility to handle sudo -A calls in your system"
 sudo sh -c 'echo "Path askpass /usr/bin/ssh-askpass" > /etc/sudo.conf' 
fi


#Do you want to setup a Web proxy on this machine?
#This can provide a boost in your web browsing
#sudo apt-get install squid3 
#If squid is found the rest will autocomplete..! The proxy will work on local network machines port 3128

#Create shared directory
if [ -f /etc/squid/squid.conf ]
then
 USER=`whoami`
 mkdir -p /home/$USER/cache/
 echo "http_access allow localnet"  >> /etc/squid/conf.d/myProxy.conf
 echo "acl localnet src 192.168.1.0/255.255.255.0"  >> /etc/squid/conf.d/myProxy.conf
 echo "cache_dir diskd /home/$USER/cache 100 16 256"  >> /etc/squid/conf.d/myProxy.conf
 echo "#Don't forget to run this if you change something here"  >> /etc/squid/conf.d/myProxy.conf
 echo "#sudo systemctl restart squid.service"  >> /etc/squid/conf.d/myProxy.conf
 sudo systemctl restart squid.service
fi
 

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



#https://make-linux-fast-again.com/
# echo "GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash noibrs noibpb nopti nospectre_v2 nospectre_v1 l1tf=off nospec_store_bypass_disable no_stf_barrier mds=off tsx=on tsx_async_abort=off mitigations=off\"" >> /etc/default/grub

#firefox https://addons.mozilla.org/en-US/firefox/addon/tab-list/&
#firefox https://addons.mozilla.org/en-US/firefox/addon/os-x-yosemite/&
#firefox https://addons.mozilla.org/en-US/firefox/addon/noscript/&
firefox https://addons.mozilla.org/en-US/firefox/addon/adblock-plus/?src=ss&
firefox https://addons.mozilla.org/en-US/firefox/addon/user-agent-switcher-revived/
#firefox https://addons.mozilla.org/en-US/firefox/addon/video-downloadhelper/&
#firefox https://addons.mozilla.org/en-US/firefox/addon/download-youtube/&

#Hit about:config
#set browser.sessionhistory.max_entries 10
#set browser.cache.memory.enable 2048


echo "Using a nice selection of XScreensavers"
cd "$DIR"
wget https://raw.githubusercontent.com/AmmarkoV/MyScripts/master/Setup/xscreensaver
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



#Add sound when booting
#sudo echo "GRUB_INIT_TUNE=\"1750 523 1 392 1 523 1 659 1 784 1 1047 1 784 1 415 1 523 1 622 1 831 1 622 1 831 1 1046 1 1244 1 1661 1 1244 1 466 1 587 1 698 1 932 1 1195 1 1397 1 1865 1 1397 1\"" >> /etc/default/grub
#sudo update-grub



#Don't use firefox snap
#sudo snap remove firefox
#sudo install -d -m 0755 /etc/apt/keyrings
#wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
#echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee -a /etc/apt/sources.list.d/mozilla.list > /dev/null
#echo '
#Package: *
#Pin: origin packages.mozilla.org
#Pin-Priority: 1000
#' | sudo tee /etc/apt/preferences.d/mozilla
#sudo apt update && sudo apt install firefox
 

#Install Steam
#Steam needs 32bit libc
#sudo apt-get install libc6-i386 libgl1-mesa-glx:i386
#wget -O ~/Downloads/steam.deb "https://cdn.cloudflare.steamstatic.com/client/installer/steam.deb"
#dpkg -i ~/Downloads/steam.deb

#Install Discord 
#wget -O /tmp/discord-installer.deb "https://discordapp.com/api/download/canary?platform=linux&format=deb"
#dpkg -i /tmp/discord-installer.deb
 


neofetch
echo "Configuration Complete" |  festival --tts




# sensors-applet
exit 0
