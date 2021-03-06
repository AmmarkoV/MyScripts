#!/bin/bash

FILE1="linux-headers-4.4.0-040400_4.4.0-040400.201601101930_all.deb"
FILE2="linux-headers-4.4.0-040400-generic_4.4.0-040400.201601101930_amd64.deb"
FILE3="linux-image-4.4.0-040400-generic_4.4.0-040400.201601101930_amd64.deb"
SITE="http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.4-wily"
 
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
