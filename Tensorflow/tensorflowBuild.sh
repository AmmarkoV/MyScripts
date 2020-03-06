#!/bin/bash

#build script for Ubuntu 18.04 
#with cuda 10.0

cd ~/Documents
mkdir 3dParty
cd 3dParty

wget http://ammar.gr/mocapnet/bazel-0.24.1-installer-linux-x86_64-fortensorflow-r1.15.sh
chmod +x bazel-0.24.1-installer-linux-x86_64-fortensorflow-r1.15.sh
./bazel-0.24.1-installer-linux-x86_64-fortensorflow-r1.15.sh --user

#Create shared directory
if [ -f ~/.bashrc ]
then 
 if cat ~/.bashrc | grep -q "BAZEL_CANCER"
then
   echo "Bazel includes seem to be set-up.." 
else 
  USER=`whoami` 
  echo "#Bazel cancer.." >> ~/.bashrc
  echo "source ~/.bazel/bin/bazel-complete.bash" >> ~/.bashrc
  echo "export PATH=\"\$PATH:\$HOME/bin\"" >> ~/.bashrc 
 fi
fi


git clone https://github.com/tensorflow/tensorflow.git
cd tensorflow
git checkout r1.15
./configure

bazel build --config=opt --config=cuda --config=mkl --local_resources 2048,.5,1.0  //tensorflow/tools/pip_package:build_pip_package
./bazel-bin/tensorflow/tools/pip_package/build_pip_package ~/Documents/3dParty/


bazel build --config opt //tensorflow/tools/lib_package:libtensorflow
mv bazel-bin/tensorflow/tools/lib_package/libtensorflow.tar.gz ~/Documents/3dParty/libtensorflow-r1.15.tar.gz


exit 0
