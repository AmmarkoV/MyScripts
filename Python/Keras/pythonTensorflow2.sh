#!/bin/bash

sudo apt-get install python3-venv python3-tk
python3 -m venv tensorflow2
source tensorflow2/bin/activate
pip install --upgrade pip
pip install tensorflow
pip install numpy
#pip install tensorflow_gpu
pip install keras 
pip install pillow
pip install matplotlib 
pip install pydot


exit 0
