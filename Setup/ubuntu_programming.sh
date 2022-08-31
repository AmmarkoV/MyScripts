#!/bin/bash
echo "Ammar's Ubuntu programming Packages :P "

#sudo add-apt-repository ppa:damien-moore/codeblocks-stable
#sudo apt-get update

#codeblocks codeblocks-contrib wxformbuilder

sudo apt-get install build-essential codelite codelite-plugins blender dia git  gource cmake mesa-utils wx-common libwxgtk3.0-gtk3-dev valgrind  sysprof htop hardinfo gtkperf  patchutils  doxygen doxygen-gui arbtt ghex chrpath cppcheck screen bluefish kcachegrind astyle
#schedutils mysql-workbench gitstats valkyrie
#schedutils



#Add legacy ssh connection for old git servers
if [ -f /etc/ssh_config ]
then 
 if cat /etc/ssh_config | grep -q "HostKeyAlgorithms"
then
   echo "Legacy GIT ssh algorithms seems to be already set-up.." 
else 
 echo "HostKeyAlgorithms +ssh-rsa,ssh-dss"  >> /etc/ssh_config 
 sudo systemctl restart ssh
 fi
fi



#Visual Studio
#As seen in : https://www.ubuntupit.com/visual-studio-code-a-free-and-open-source-code-editor-for-ubuntu/
#sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
#curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
#sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
#sudo apt-get update && sudo apt-get dist-upgrade
#sudo apt-get install code



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
