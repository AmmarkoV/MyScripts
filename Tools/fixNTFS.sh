#!/bin/bash

sudo apt-get install ntfs-3g
sudo ntfsfix -b -d $1


exit 0
