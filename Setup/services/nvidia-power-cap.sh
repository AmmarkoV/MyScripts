#!/bin/bash

WATTS="180"
echo "Setting GPU to $WATTS W" 
sudo nvidia-smi -pl $WATTS

exit 0

