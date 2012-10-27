#!/bin/bash
echo "Ubuntu Server Handy Packages :P "
sudo apt-get install mplayer sysv-rc-conf festival lm-sensors vsftpd mumble-server apache2 php5 php5-mysql php5-gd libapache2-mod-php5 beep

echo "Configuring VSFTPD with AmmarSettings! :P";
#wget http://ammar.gr/~ammar/vsftpd.conf
sudo mv /etc/vsftpd.conf /etc/vsftpd_default.conf  
sudo mv vsftpd.conf /etc/vsftpd.conf  
sudo chown root:root /etc/vsftpd.conf
sudo touch /etc/vsftpd.banned_emails
sudo /etc/init.d/vsftpd restart
echo "VSFTPD ok..";

echo "Enable Apache user directories ( ~/ammar ) ok..";
sudo a2enmod userdir 
sudo a2enmod headers
sudo a2enmod rewrite
sudo a2enmod expires
sudo a2enmod php5
sudo /etc/init.d/apache2 restart

sudo useradd -d /home/ammar/ -m ammar 
sudo mkdir /home/ammar/public_html/
sudo chmod 755 /home/ammar/public_html/


echo "enter new pass for user ammar ( master public folder )";

sudo passwd ammar
sudo usermod -a -G video ammar
sudo usermod -a -G audio ammar

echo "Trying to Detect Sensor Settings! :P";
sudo sensors-detect

echo "Mumble Super User "
echo "murmurd -supw SuperUserPasswordHere"


echo "Installation Complete" | esddsp festival --tts

echo "\nThings todo (?) : "
echo "CLONE DATA--------------- "
echo "wget -r 'ftp://user:pass@domain' "
echo " "

echo "APACHE2--------------- "
echo "AllowOverride All -> sudo nano /etc/apache2/sites-enabled/000-default"
echo "ADD to -> /etc/apache2/mods-enabled/php5.conf"
echo " "
echo "<IfModule mod_php5.c>"
echo "AddType application/x-httpd-php .php .phtml .php3"
echo "AddType application/x-httpd-php-source .phps"
echo "</IfModule>"
echo " "

echo "MYSQL GRANT LAN PERMISSIONS--------------- "
echo "sudo nano /etc/mysql/my.conf to change bind_address to 0.0.0.0"
echo "sudo /etc/init.d/mysql restart"
echo "mysql -u root -p mysql"
echo "GRANT ALL ON *.* TO root@'192.168.1.2' IDENTIFIED BY 'YOURPASSWORDGOESHERE';"
echo "FLUSH PRIVILEGES;"
echo "quit"
echo "You can now connect from 192.168.1.2 using mysql administrator"
echo " " 
echo " "

echo "MYSQL GRANT LAN PERMISSIONS--------------- "
echo " "

echo "MYSQL BACKUP SCRIPT--------------- "
echo "mysqldump -u root -pPASSWORD --all-databases | gzip > /home/ammarroot/mysql_`date +"%m-%d-%Y"`.sql.gz" 


sudo cp /etc/awstats/awstats.conf /etc/awstats/awstats.ammar.gr.conf
echo "make the following changes:"
echo 'LogFile="/var/log/apache2/access.log"' 
echo 'SiteDomain="ammar.gr"'
echo 'HostAliases="localhost 127.0.0.1 ammar.gr"'

sudo nano /etc/awstats/awstats.ammar.gr.conf

echo "now run"
echo "/usr/lib/cgi-bin/awstats.pl -config=ammar.gr -update"

echo "and add to /etc/apache2/sites-available/default"
echo 'Alias /awstatsclasses "/usr/share/awstats/lib/"'
echo 'Alias /awstats-icon/ "/usr/share/awstats/icon/"'
echo 'Alias /awstatscss "/usr/share/doc/awstats/examples/css"'
echo 'ScriptAlias /awstats/ /usr/lib/cgi-bin/'
echo 'Options ExecCGI -MultiViews +SymLinksIfOwnerMatch'


exit 0
