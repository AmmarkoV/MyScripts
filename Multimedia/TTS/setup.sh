#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

python3 -m venv venv
source venv/bin/activate

sudo apt-get install espeak-ng 

python3 -m pip install kokoro soundfile gradio

#LD_PRELOAD=/usr/local/cuda-12.4/lib64/libcusparse.so.12 python3 tts.py 
#LD_PRELOAD=/usr/local/cuda-12.4/lib64/libcusparse.so.12 python3 server.py 


exit 0
