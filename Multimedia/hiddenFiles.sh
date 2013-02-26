#!/bin/bash

find -iname "*.jpg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.jpeg" -o -exec 7z x "{}" -o/tmp/ \;

exit 0
