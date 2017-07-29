#!/bin/bash

sudo apt-get update && sudo apt-get upgrade && sudo apt-get dist-upgrade
sudo apt-get install rpi-update kodi git cmake build-essential vlc smplayer audacious libsdl1.2-dev mesa-utils supertux python libusb-1.0-0-dev freeglut3-dev doxygen graphviz
sudo rpi-update 

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
git clone https://github.com/ioquake/ioq3/

mkdir mesabackup
cd mesabackup
apt-get download libdrm-freedreno1 libgl1-mesa-dri libegl1-mesa libglapi-mesa libgl1-mesa-glx libgles1-mesa libgles2-mesa libglu1-mesa libwayland-egl1-mesa mesa-utils libgbm1
cd ..

mkdir mesa 
cd mesa 
wget https://launchpad.net/ubuntu/+source/mesa/11.1.1-1ubuntu2/+build/8881184/+files/libegl1-mesa_11.1.1-1ubuntu2_armhf.deb https://launchpad.net/ubuntu/+source/mesa/11.1.1-1ubuntu2/+build/8881184/+files/libgl1-mesa-dri_11.1.1-1ubuntu2_armhf.deb https://launchpad.net/ubuntu/+source/mesa/11.1.1-1ubuntu2/+build/8881184/+files/libgl1-mesa-glx_11.1.1-1ubuntu2_armhf.deb https://launchpad.net/ubuntu/+source/mesa/11.1.1-1ubuntu2/+build/8881184/+files/libglapi-mesa_11.1.1-1ubuntu2_armhf.deb https://launchpad.net/ubuntu/+source/mesa/11.1.1-1ubuntu2/+build/8881184/+files/libgles1-mesa_11.1.1-1ubuntu2_armhf.deb https://launchpad.net/ubuntu/+source/mesa/11.1.1-1ubuntu2/+build/8881184/+files/libgles2-mesa_11.1.1-1ubuntu2_armhf.deb http://launchpadlibrarian.net/234263009/libdrm-freedreno1_2.4.66-2_armhf.deb1 http://launchpadlibrarian.net/222366701/libglu1-mesa_9.0.0-2.1_armhf.deb http://launchpadlibrarian.net/222366701/libglu1-mesa_9.0.0-2.1_armhf.deb http://launchpadlibrarian.net/234861434/libwayland-egl1-mesa_11.1.1-1ubuntu2_armhf.deb http://launchpadlibrarian.net/229716045/mesa-utils_8.3.0-1_armhf.deb http://launchpadlibrarian.net/234861425/libgbm1_11.1.1-1ubuntu2_armhf.deb http://launchpadlibrarian.net/222366701/libglu1-mesa_9.0.0-2.1_armhf.deb http://launchpadlibrarian.net/234861434/libwayland-egl1-mesa_11.1.1-1ubuntu2_armhf.deb http://launchpadlibrarian.net/229716045/mesa-utils_8.3.0-1_armhf.deb

exit 0
