#!/bin/bash

 svn log  | grep $1  | cut -d '|' -f 4 | cut -d ' ' -f2 |  paste -sd+ | bc

exit 0
