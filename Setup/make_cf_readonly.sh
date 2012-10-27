#!/bin/bash
echo "Make CF Read Only"
mount -o remount,ro /
mount -o remount,ro /var/
mount -o remount,ro /boot/
