#!/bin/bash
sudo apt-get install lxde
echo "Change Language : setxkbmap -option
 grp:switch,grp:alt_shift_toggle,grp_led:scroll us,gr"
echo "sudo nano /etc/xdg/lxsession/LXDE/autostart"
echo "@nm-applet"
echo "@setxkbmap -option grp:switch,grp:alt_shift_toggle,grp_led:scroll us,gr"

exit 0
