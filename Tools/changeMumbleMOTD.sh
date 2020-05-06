#!/bin/bash
IMAGE_BASE64="<img alt=\\\"Welcome Message\\\" src=\\\"data:image/jpeg;base64,$(base64 -w $1)\\\"/>"

echo $IMAGE_BASE64


exit 0
