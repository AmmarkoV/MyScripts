#!/bin/bash
sudo modprobe dvb_usb_v2 
sudo modprobe rtl2832
sudo modprobe rtl2832_sdr 
sudo modprobe dvb_usb_rtl28xxu

w_scan -ft -c GR -X -t 3 >> channels.conf
me-tv
exit 0
