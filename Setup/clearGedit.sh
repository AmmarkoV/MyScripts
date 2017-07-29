#!/bin/bash

sudo apt-get purge gedit
sudo rm -r ~/.local/share/gedit/* 2> /dev/null
sudo rm -r /usr/lib/gedit/* 2> /dev/null
sudo rm -r /usr/share/glib-2.0/schemas/org.gnome.gedit.plugins.* 2> /dev/null
sudo apt-get install gedit

exit 0
