#!/bin/bash

SIZE="16G"
NAME="/swapfile2"

sudo fallocate -l $SIZE $NAME
sudo chmod 600 $NAME
sudo mkswap $NAME
sudo swapon $NAME
echo "$NAME swap swap defaults 0 0" | sudo tee -a /etc/fstab

exit 0
