#!/bin/bash



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
 echo "plasmawindowed org.kde.kdeconnect --statusnotifier" >> ~/.autostart.sh
 echo "sleep 10" >> ~/.autostart.sh
 echo "kodi" >> ~/.autostart.sh
 echo "exit 0" >> ~/.autostart.sh 
 chmod +x ~/.autostart.sh 
fi



if [ -f ~/Desktop/stopKodi.sh ]
then 
 echo "Found per-user autostart stop kodi bash script"
else 
 echo "Generating new per-user autostart bash script"
 echo "#!/bin/bash" > ~/Desktop/stopKodi.sh
 echo "killall .autostart.sh kodi" >> ~/Desktop/stopKodi.sh
 echo "exit 0" >> ~/Desktop/stopKodi.sh
 chmod +x ~/Desktop/stopKodi.sh
fi



exit 0
