#!/bin/bash

#Tensorflow is a great Neural network library that unfortunately is coupled to the terrible Bazel build system
#This is a download and build script for Ubuntu 18.04, that should work building release 1.15  

sudo apt-get install python3-dev python3-pip python3-venv python3-tk gcc-6 g++-6

pip install -U --user pip six numpy wheel setuptools mock 'future>=0.17.1'
pip install -U --user keras_applications --no-deps
pip install -U --user keras_preprocessing --no-deps


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

echo "Please specify the following path in the brilliant configuration script"
echo "/usr/bin/gcc-6"


./configure

bazel clean --expunge
bazel build --config=opt --config=cuda --config=mkl --cxxopt="-D_GLIBCXX_USE_CXX11_ABI=0" --local_resources 2048,.5,1.0  //tensorflow/tools/pip_package:build_pip_package
./bazel-bin/tensorflow/tools/pip_package/build_pip_package ~/Documents/3dParty/


bazel build --config opt //tensorflow/tools/lib_package:libtensorflow
mv bazel-bin/tensorflow/tools/lib_package/libtensorflow.tar.gz ~/Documents/3dParty/libtensorflow-r1.15.tar.gz


exit 0
