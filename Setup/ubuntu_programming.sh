#!/bin/bash
echo "Ammar's Ubuntu programming Packages :P "

sudo add-apt-repository ppa:damien-moore/codeblocks-stable
sudo apt-get update

sudo apt-get install build-essential codeblocks codeblocks-contrib wxformbuilder blender dia git gitstats gource cmake mesa-utils wx-common libwxgtk2.8-dev libwxbase2.8-dbg libwxgtk2.8-dbg wx2.8-examples valgrind valkyrie gnotime sysprof htop hardinfo gtkperf  patchutils mysql-workbench doxygen doxygen-gui arbtt ghex chrpath cppcheck screen bluefish kcachegrind
#schedutils
echo "Installation Complete" | esddsp festival --tts
exit 0
