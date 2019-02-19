#!/bin/bash

sudo apt-get install openvpn network-manager-openvpn network-manager-openvpn-gnome


mkdir ~/vpn
cd ~/vpn
wget https://webmail.ics.forth.gr/guide/ca.crt
wget https://webmail.ics.forth.gr/guide/client.ovpn
DIR=`pwd`
echo "Don't forget to change client.ovpn and update the path to the crt file to $DIR/ca.crt"
exit 0
