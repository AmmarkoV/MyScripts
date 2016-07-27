#!/bin/bash

FILE1="linux-headers-4.7.0-040700_4.7.0-040700.201607241632_all.deb"
FILE2="linux-headers-4.7.0-040700-generic_4.7.0-040700.201607241632_amd64.deb"
FILE3="linux-image-4.7.0-040700-generic_4.7.0-040700.201607241632_amd64.deb"
SITE="http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.7/"
 
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
