#!/bin/bash

cd ~

sudo apt install libffi-dev libssl-dev openssl


#Modules/Setup.dist
# _socket socketmodule.c <- uncomment this line

# Socket module helper for SSL support; you must comment out the other
# socket line above, and possibly edit the SSL variable:
#SSL=/usr/local/ssl
#_ssl _ssl.c \ <- uncomment this line
# -DUSE_SSL -I$(SSL)/include -I$(SSL)/include/openssl \ <- uncomment this line
# -L$(SSL)/lib -lssl -lcrypto  <- uncomment this line


wget https://www.python.org/ftp/python/3.7.0/Python-3.7.0.tgz
tar xzf Python-3.7.0.tgz
cd Python-3.7.0
./configure --enable-optimizations
sudo make altinstall
rm /usr/src/Python-3.7.0.tgz

exit 0

