#!/bin/bash

#KERNEL=="nvidia_uvm", RUN+="/usr/bin/bash -c '/bin/mknod -m 660 /dev/nvidia-uvm c $(grep nvidia-uvm /proc/devices | cut -d \  -f 1) 0; /bin/chgrp video /dev/nvidia-uvm'"

#Edit the file /etc/modprobe.d/bumblebee.conf
#alias nvidia-uvm nvidia-340-uvm


sudo update-alternatives --config x86_64-linux-gnu_gl_conf
exit 0
