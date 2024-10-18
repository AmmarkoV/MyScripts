#/bin/bash
adb kill-server
sudo adb devices
adb install $@

exit 0


