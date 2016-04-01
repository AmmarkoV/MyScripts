#!/bin/bash

sudo apt-get update && sudo apt-get upgrade && sudo apt-get dist-upgrade
sudo apt-get install kodi git cmake build-essential vlc smplayer audacious libsdl1.2-dev

cd ~/
mkdir Programs
cd Programs/ 


git clone https://github.com/libretro/pcsx_rearmed
cd pcsx_rearmed
git submodule init && git submodule update
./configure

cd ~/Programs
git clone git://github.com/AmmarkoV/AmmarServer
git clone git://github.com/AmmarkoV/FlashySlideshows


exit 0
