#!/bin/bash



while :
do 


if pgrep -x "xscreensaver" >/dev/null
then
   sleep 10
else
    echo "XScreenSaver crashed ?"
    xscreensaver -nosplash
fi
 sleep 10
done 

exit 0
