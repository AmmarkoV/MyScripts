#!/bin/bash

mkdir -p ~/Documents/3dParty
cd ~/Documents/3dParty

sudo apt-get install libpng-dev libjpeg-dev libtiff-dev libxxf86vm1 libxxf86vm-dev libxi-dev libxrandr-dev libopenimageio-dev libceres-dev graphviz

#-------------------------------------------
#                  GEOGRAM 
#-------------------------------------------
git clone https://github.com/alicevision/geogram
cd geogram/
./configure
cd build/Linux64-gcc-dynamic-Release
make 
sudo make install
cd ..
cd ..
cd ..

#-------------------------------------------
#                ALICEVISION 
#-------------------------------------------
git clone --recursive git://github.com/alicevision/AliceVision
cd AliceVision
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release -DALICEVISION_BUILD_TESTS=ON -DALICEVISION_BUILD_EXAMPLES=ON ../AliceVision
cd ..
cd ..


#-------------------------------------------
#                  MESHROOM 
#-------------------------------------------
git clone --recursive git://github.com/alicevision/meshroom
cd meshroom
#pip install pyside2 pyqt5 --user
#pip install -r requirements.txt -r dev_requirements.txt
cd ..

#QML2_IMPORT_PATH=/path/to/qmlAlembic/install/qml
#QT_PLUGIN_PATH=/path/to/QtOIIO/install
#QML2_IMPORT_PATH=/path/to/QtOIIO/install/qml


#-------------------------------------------

ALICEVISION_SENSOR_DB=/home/ammar/Documents/3dParty/AliceVision/src/aliceVision/sensorDB
ALICEVISION_VOCTREE=/home/ammar/Documents/3dParty/AliceVision/src/aliceVision/voctree
LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/ammar/Documents/3dParty/AliceVision 
PATH=$PATH:/home/ammar/Documents/3dParty/AliceVision 
cd meshroom
PYTHONPATH=$PWD python meshroom/ui

exit 0
