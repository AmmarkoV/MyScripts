#!/bin/bash

#KERNEL=="nvidia_uvm", RUN+="/usr/bin/bash -c '/bin/mknod -m 660 /dev/nvidia-uvm c $(grep nvidia-uvm /proc/devices | cut -d \  -f 1) 0; /bin/chgrp video /dev/nvidia-uvm'"

#Edit the file /etc/modprobe.d/bumblebee.conf
#alias nvidia-uvm nvidia-340-uvm


sudo update-alternatives --config x86_64-linux-gnu_gl_conf

#  Selection    Path                                       Priority   Status
#------------------------------------------------------------
#  0            /usr/lib/nvidia-361/ld.so.conf              8604      auto mode
#  1            /usr/lib/nvidia-361-prime/ld.so.conf        8603      manual mode
#  2            /usr/lib/nvidia-361/ld.so.conf              8604      manual mode
#* 3            /usr/lib/x86_64-linux-gnu/mesa/ld.so.conf   500       manual mode


#sudo nano /etc/modprobe.d/bumblebee.conf
#make sure the nvidia driver is blacklisted there


#sudo nano /etc/bumblebee/bumblebee.conf
#KernelDriver=nvidia-361
#PMMethod=auto
#LibraryPath=/usr/lib/nvidia-361:/usr/lib32/nvidia-361
#XorgModulePath=/usr/lib/nvidia-361/xorg,/usr/lib/xorg/modules






exit 0
