#!/bin/bash

INSTALL_DIR="~/Documents/3dParty"

mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

sudo apt-get install libpng-dev libjpeg-dev libtiff-dev libxxf86vm1 libxxf86vm-dev libxi-dev libxrandr-dev libceres-dev graphviz #libopenimageio-dev 

#-------------------------------------------
#                  OpenImageIO 
#-------------------------------------------
git clone https://github.com/OpenImageIO/oiio
cd oiio
OIIODIR=`pwd`
mkdir build && cd build
cmake .. 
make
sudo make install
cd $INSTALL_DIR

#-------------------------------------------
#                  GEOGRAM 
#-------------------------------------------
git clone https://github.com/alicevision/geogram
cd geogram/
./configure
cd build/Linux64-gcc-dynamic-Release
GEOGRAMDIR=`pwd`
make 
sudo make install
cd $INSTALL_DIR

#-------------------------------------------
#                ALICEVISION 
#-------------------------------------------
git clone --recursive git://github.com/alicevision/AliceVision
cd AliceVision
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release -DALICEVISION_BUILD_TESTS=ON -DALICEVISION_BUILD_EXAMPLES=ON -DGEOGRAM_GFX_LIBRARY=$GEOGRAMDIR/lib/libgeogram_gfx.so -DGEOGRAM_GLFW3_LIBRARY=$GEOGRAMDIR/lib/libglfw.so.3 -DGEOGRAM_INCLUDE_DIR=$GEOGRAMDIR/src/lib -DGEOGRAM_LIBRARY=$GEOGRAMDIR/lib/libgeogram.so -DOPENIMAGEIO_LIBRARY=$OIIODIR/build/src/libOpenImageIO/libOpenImageIO.so  -DOPENIMAGEIO_INCLUDE_DIR=$OIIODIR/src/include  ..
make
cd $INSTALL_DIR


#-------------------------------------------
#                  MESHROOM 
#-------------------------------------------
git clone --recursive git://github.com/alicevision/meshroom
cd meshroom
#pip install pyside2 pyqt5 --user
#pip install -r requirements.txt -r dev_requirements.txt
cd $INSTALL_DIR

#QML2_IMPORT_PATH=/path/to/qmlAlembic/install/qml
#QT_PLUGIN_PATH=/path/to/QtOIIO/install
#QML2_IMPORT_PATH=/path/to/QtOIIO/install/qml
#-------------------------------------------
#               TRY TO RUN
#-------------------------------------------

ALICEVISION_SENSOR_DB=/home/ammar/Documents/3dParty/AliceVision/src/aliceVision/sensorDB
ALICEVISION_VOCTREE=/home/ammar/Documents/3dParty/AliceVision/src/aliceVision/voctree
LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/ammar/Documents/3dParty/AliceVision 
PATH=$PATH:/home/ammar/Documents/3dParty/AliceVision 
cd meshroom
PYTHONPATH=$PWD python meshroom/ui

exit 0
