#!/bin/bash
echo "Ammar's Ubuntu programming Packages :P "

#sudo add-apt-repository ppa:damien-moore/codeblocks-stable
#sudo apt-get update

#codeblocks codeblocks-contrib wxformbuilder

sudo apt-get install build-essential codelite codelite-plugins blender dia git gitstats gource cmake mesa-utils wx-common libwxgtk3.0-dev valgrind valkyrie sysprof htop hardinfo gtkperf  patchutils mysql-workbench doxygen doxygen-gui arbtt ghex chrpath cppcheck screen bluefish kcachegrind  astyle
#schedutils

#Code lite...
#------------------------------------------------
echo "Now installing codelite"
mkdir -p ~/Documents/3dParty
cd ~/Documents/3dParty
git clone https://github.com/eranif/codelite
sudo apt-get install libgtk2.0-dev pkg-config build-essential git cmake libssh-dev libwxbase3.0-dev libsqlite3-dev libwxsqlite3-3.0-dev
cd codelite 
mkdir build-release
cd build-release
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . 
sudo cmake --build . --target install

echo "Dont forget to change the font to Ubuntu Mono to fix the weird font issues" 
#------------------------------------------------

echo "Installation Complete" | esddsp festival --tts
exit 0
