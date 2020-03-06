#!/bin/bash

#Tensorflow is a great Neural network library that unfortunately is coupled to the terrible Bazel build system
#This is a download and build script for Ubuntu 18.04, that should work building release 1.15  


cd ~/Documents
mkdir 3dParty
cd 3dParty

wget http://ammar.gr/mocapnet/bazel-0.24.1-installer-linux-x86_64-for-tensorflow-r1.15.sh
chmod +x bazel-0.24.1-installer-linux-x86_64-for-tensorflow-r1.15.sh
./bazel-0.24.1-installer-linux-x86_64-for-tensorflow-r1.15.sh --user

#Create shared directory
if [ -f ~/.bashrc ]
then 
 if cat ~/.bashrc | grep -q "BAZEL_CANCER"
then
   echo "Bazel includes seem to be set-up.." 
else 
  USER=`whoami` 
  echo "#BAZEL_CANCER" >> ~/.bashrc
  echo "source ~/.bazel/bin/bazel-complete.bash" >> ~/.bashrc
  echo "export PATH=\"\$PATH:\$HOME/bin\"" >> ~/.bashrc
  source ~/.bashrc 
 fi
fi

if [ ! -d tensorflow ]
then 
git clone https://github.com/tensorflow/tensorflow.git
fi

cd tensorflow
git pull
git checkout r1.15
./configure

bazel build --config=opt --config=cuda --config=mkl --local_resources 2048,.5,1.0  //tensorflow/tools/pip_package:build_pip_package
./bazel-bin/tensorflow/tools/pip_package/build_pip_package ~/Documents/3dParty/


bazel build --config opt //tensorflow/tools/lib_package:libtensorflow
mv bazel-bin/tensorflow/tools/lib_package/libtensorflow.tar.gz ~/Documents/3dParty/libtensorflow-r1.15.tar.gz


exit 0
