#!/bin/bash

FILE1="linux-headers-4.6.0-040600_4.6.0-040600.201605151930_all.deb"
FILE2="linux-headers-4.6.0-040600-generic_4.6.0-040600.201605151930_amd64.deb"
FILE3="linux-image-4.6.0-040600-generic_4.6.0-040600.201605151930_amd64.deb"
SITE="http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.6-yakkety/"
 
if [ -e $FILE1 ] 
then
 echo "Already have $FILE1"
else
 wget $SITE/$FILE1
fi
#==============================================
if [ -e $FILE2 ] 
then
 echo "Already have $FILE2"
else
 wget $SITE/$FILE2
fi
#==============================================
if [ -e $FILE3 ] 
then
 echo "Already have $FILE3"
else
 wget $SITE/$FILE3
fi


sudo dpkg -i $FILE1 $FILE2 $FILE3

sudo dpkg-reconfigure nvidia-*
#sudo apt-get install linux-headers-$(uname -r) build-essential dkms git


exit 0
