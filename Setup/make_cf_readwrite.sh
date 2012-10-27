#!/bin/bash
echo "Make CF Read Write"
mount -o remount,rw /
mount -o remount,rw /var/
mount -o remount,rw /boot/
