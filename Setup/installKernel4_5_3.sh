#!/bin/bash

FILE1="linux-headers-4.5.3-040503_4.5.3-040503.201605041831_all.deb"
FILE2="linux-headers-4.5.3-040503-generic_4.5.3-040503.201605041831_amd64.deb"
FILE3="linux-image-4.5.3-040503-generic_4.5.3-040503.201605041831_amd64.deb"
SITE="http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.5.3-wily/"
 
if [ -e $FILE1 ] 
 echo "Already have $FILE1"
elif
 wget $SITE/$FILE1
fi
#==============================================
if [ -e $FILE2 ] 
 echo "Already have $FILE2"
elif
 wget $SITE/$FILE2
fi
#==============================================
if [ -e $FILE3 ] 
 echo "Already have $FILE3"
elif
 wget $SITE/$FILE3
fi



sudo dpkg -i $FILE1 $FILE2 $FILE3

sudo dpkg-reconfigure nvidia-*
#sudo apt-get install linux-headers-$(uname -r) build-essential dkms git


exit 0
