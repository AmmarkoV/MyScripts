#!/bin/bash

grep -cve '^\s*$' */*.$1 | cut -d ':' -f2 |  paste -sd+ | bc


exit 0
