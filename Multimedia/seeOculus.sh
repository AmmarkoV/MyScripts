#/bin/bash
adb kill-server
sudo adb devices
adb exec-out "while true; do screenrecord --bit-rate=2m --output-format=h264 --time-limit 180 -; done" | cvlc --demux h264 --h264-fps=60 --clock-jitter=0 -
exit 0
