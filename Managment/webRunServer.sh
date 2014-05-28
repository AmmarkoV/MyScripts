#!/bin/bash

while true; do
 nc6 -l -p 8080 -e "/bin/bash webRun.sh"
 sleep 1
done 


exit 0
