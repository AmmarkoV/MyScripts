#!/bin/bash
gksudo /usr/bin/nvidia-smi -pm 1
echo 7 > /proc/sys/kernel/printk
cat /proc/interrupts 
cat /proc/meminfo
exit 0