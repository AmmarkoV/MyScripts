#!/bin/bash

sudo apt-get install python3-venv 
python3 -m venv tensorflow
source tensorflow/bin/activate
pip install numpy
pip install tensorflow
pip install keras 


exit 0
