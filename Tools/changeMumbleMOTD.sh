#!/bin/bash
IMAGE_BASE64="<img alt=\\\"Welcome Message\\\" src=\\\"data:image/jpeg;base64,$(base64 -w 0 motd.jpg)\\\"/>"

echo $IMAGE_BASE64


exit 0
