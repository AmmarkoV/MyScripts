#!/bin/bash

cat $1 | grep youtube | sort | xargs -L 1 sh -c '~/Scripts/Multimedia/DownloadYoutubeVid.pl "$0"'

exit 0