#!/bin/bash

VERSION="3.27.8" #Last stable version in 22/11/23

#sudo apt-get remove cmake cmake-data

sudo apt install build-essential libssl-dev
wget https://github.com/Kitware/CMake/releases/download/v$VERSION/cmake-$VERSION.tar.gz
tar -zxvf cmake-$VERSION.tar.gz
cd cmake-$VERSION
./bootstrap
make 
sudo make install 

exit 0
