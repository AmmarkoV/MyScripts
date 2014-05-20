#!/bin/bash
cd /
LC_ALL=C md5sum -c /var/lib/dpkg/info/*.md5sums | grep -v OK
exit 0
