#!/bin/bash

sudo apt-get install python3-venv python3-tk
python3 -m venv tensorflow
source tensorflow/bin/activate
pip install numpy
#pip install tensorflow
pip install tensorflow_gpu
pip install keras pillow matplotlib pydot


exit 0
