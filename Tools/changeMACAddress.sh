 #!/bin/bash

sudo ifdown eth0
sudo ifconfig eth0 hw ether 00:20:74:d8:5b:3a
sudo ifup eth0

exit 0
