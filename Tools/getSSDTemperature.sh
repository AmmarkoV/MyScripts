#!/bin/bash
sudo smartctl -d ata -A /dev/sdb | grep -i temperature
exit 0
