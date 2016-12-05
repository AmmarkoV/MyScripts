#!/bin/bash

wget http://10.5.5.9/gp/gpControl/execute?p1=gpStream&c1=restart
ffplay -fflags nobuffer -f:v mpegts -probesize 8192 udp::8554


exit 0
