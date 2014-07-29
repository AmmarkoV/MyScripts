#!/bin/bash
cd /home/ammar/
dpkg --get-selections > packageList.txt
cd /
mysqldump -u root -pPASS_HERE --all-databases | gzip > /home/ammar/mysql/mysql_`date +"%m-%d-%Y"`.sql.gz
rm /home/ammar/backup.*
sudo tar -cvpj /home/ | sudo split -d -b 4000m - backup.tar.bz2.
sudo mv backup.* ammar/
#sudo tar cvf backup.tar . 
#sudo mv backup.tar /home/ammar/backup.tar
exit 0
