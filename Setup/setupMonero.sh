#!/bin/bash

cd ~/Documents
mkdir 3dParty
cd 3dParty
git clone https://github.com/fireice-uk/xmr-stak/
cd xmr-stak/
git checkout xmr-stak-rx
mkdir build
cd build
sudo apt-get install build-essential cmake libssl-dev libhwloc-dev libmicrohttpd-dev 
cmake -DMICROHTTPD_ENABLE=OFF  -DCUDA_ENABLE=OFF  -DOPENCL_ENABLE=OFF ..
make -j4

exit 0
