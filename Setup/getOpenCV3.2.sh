#/bin/bash

if (( $# != 1 )); then
    echo "Please run giving the path to download and build"
    echo "$0 \"~/path/to/download_build/\" " 
   exit 0
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"


cd "$1"
echo "Will Install @ `pwd`"

echo "Downloading"

wget http://ammar.gr/programs/opencv-3.2.0.zip
wget http://ammar.gr/programs/opencv_contrib-3.2.0.tar.gz

echo "Extracting"

tar xvzf opencv_contrib-3.2.0.tar.gz
unzip opencv-3.2.0.zip

echo "Building"

cd opencv-3.2.0
mkdir build
cd build
cmake -DOPENCV_ENABLE_NONFREE=ON -DOPENCV_EXTRA_MODULES_PATH=$1/opencv_contrib-3.2.0/modules ..
make -j5

echo "Done"

exit 0
