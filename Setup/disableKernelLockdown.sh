#!/bin/bash
sudo bash -c 'echo 1 > /proc/sys/kernel/sysrq'
sudo bash -c 'echo x > /proc/sysrq-trigger'

exit 0
