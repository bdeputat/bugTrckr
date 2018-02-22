#!/bin/bash
echo "Vagrant build scenario 192.168.56.220"

# output with some color and font weight
function drawtext() {
	tput $1
	tput setaf $2
	echo -n $3
	tput sgr0
}

# Make sure we run with root privileges
if [ $UID != 0 ];
	then
# not root, use 
	echo "This script needs root privileges, rerunning it now using !"
	 "${SHELL}" "$0" $*
	exit $?
fi
# get real username
if [ $UID = 0 ] && [ ! -z "$_USER" ];
	then
	USER="$_USER"
else
	USER="$(whoami)"
fi

# SetTimeZone
timedatectl set-timezone Europe/Kiev


# <----- WorkSpace configurate ------>


# Create Install Environment Variables
#	WorkSpace
HOME_DIR="tomcat_MYSQL"
LOG_FILE=/$HOME_DIR/scenario.log

cd /

if [ ! -d ${HOME_DIR} ] 
then
# Create WorkSpace 
mkdir ${HOME_DIR}
cd ${HOME_DIR}
echo "$(drawtext bold 2 "[ OK ]")" --- "Directory "$(drawtext bold 2 "${HOME_DIR}")" successfully created"
touch ${LOG_FILE} 
echo "$(drawtext bold 2 "[ OK ]")" --- "File "$(drawtext bold 2 "$LOG_FILE")" successfully created"
echo START System --- $( date +"%H-%M-%S_%d-%m-%Y") >> ${LOG_FILE} 
echo "$(drawtext bold 2 "START System")"  --- $( date +"%H-%M-%S_%d-%m-%Y")
# Update system
echo "Updating system... "
yum update -y --nogpgcheck 
echo "$(drawtext bold 2 "[ OK ]")" --- "System Updated"
# <----- Install Other Program ------>
cd /${HOME_DIR}
yum install -y mc wget net-tools firewalld --nogpgcheck 2>>${LOG_FILE}
echo "$(drawtext bold 2 "[ OK ]")" --- ""$(drawtext bold 2 "wget, GIT")" successfully installed"

#. Installing MySQL
#info: https://www.digitalocean.com/community/tutorials/how-to-install-mysql-on-centos-7
cd /${HOME_DIR} 
wget https://dev.mysql.com/get/mysql57-community-release-el7-9.noarch.rpm
rpm -ivh mysql57-community-release-el7-9.noarch.rpm 
yum -y install mysql-server 2>>${LOG_FILE}
rm -f mysql57-community-release-el7-9.noarch.rpm 2>>${LOG_FILE}
#Upgrading MySQL
yum update mysql-server
echo "$(drawtext bold 2 "[ OK ]")" --- ""$(drawtext bold 2 "MySQL")" successfully installed"
echo "Starting mysql-server"
service mysqld start 2>>${LOG_FILE}
service mysqld status  2>>${LOG_FILE}

echo "$(drawtext bold 2 ""!!Congratulations SWorkSpace CONFIGURATED!!"  - $( date +"%H-%M-%S_%d-%m-%Y")")"  

#	WorkSpace
HOME_DIR="tomcat_MYSQL"
LOG_FILE=/$HOME_DIR/scenario.log

# MySQL
# Create MySQL  Variables
MySQL_ROOT_Pass="1a_ZaraZa@"
MySQL_User="tomcat"
MySQL_User_Pass="la_3araZa"

cd ${HOME_DIR}

# Change the root password for MySQL
#info: https://stackoverflow.com/questions/33510184/change-mysql-root-password-on-centos7
echo MySQL_TMP_PASS=$(grep 'temporary password' /var/log/mysqld.log) > Pass.txt 
echo MySQL_TMP_PASS=$(grep 'temporary password' /var/log/mysqld.log | rev | cut -c1-12 | rev) >> Pass.txt 
MySQL_TMP_PASS=$(grep 'temporary password' /var/log/mysqld.log | rev | cut -c1-12 | rev) 
mysqladmin --user=root --password="$MySQL_TMP_PASS" password "$MySQL_ROOT_Pass"


#Create a new user with same name as new DB
#Info: https://chartio.com/resources/tutorials/how-to-grant-all-privileges-on-a-database-in-mysql/ 
mysql -u root -p"${MySQL_ROOT_Pass}" -e "GRANT ALL ON *.* TO '${MySQL_User}'@'%' IDENTIFIED BY '${MySQL_User_Pass}';" 2>>${LOG_FILE}
mysql -u root -p"${MySQL_ROOT_Pass}" -e "FLUSH PRIVILEGES" 2>>${LOG_FILE}
echo "$(drawtext bold 2 "[ OK ]")" --- ""$(drawtext bold 2 "MySQL DATABASE")" successfully created" 2>>${LOG_FILE}

# !!!!! Configured etc/my.cfg
echo "bind-address	=0.0.0.0" >>/etc/my.cfg 

#Configure Firewalld
yum install 
systemctl start firewalld 
systemctl enable firewalld

# Add tcp PORT 3306 to firewall
echo "Allow 3306 port"
systemctl start firewalld
firewall-cmd --zone=public --add-port=3306/tcp --permanent
firewall-cmd --reload

#Add network hosts
cd ${HOME_DIR}
wget https://raw.githubusercontent.com/bdeputat/bugTrckr/master/bugTrckr_conf/hosts.local
cat hosts.local >>/etc/hosts 2>>${LOG_FILE}
rm -f hosts.local 2>>${LOG_FILE}
echo "$(drawtext bold 2 "[ OK ]")" --- ""$(drawtext bold 2 "local.hosts")" successfully created" 2>>${LOG_FILE}

else
echo APLICATION STARTED --- $( date +"%H-%M-%S_%d-%m-%Y") >> ${LOG_FILE} 
echo START APLICATION --- $( date +"%H-%M-%S_%d-%m-%Y")

echo "Starting mysql-server"
service mysqld stop 2>>${LOG_FILE}
service mysqld start 2>>${LOG_FILE}
service mysqld status  2>>${LOG_FILE}

fi

# <----- WorkSpace configurated ------>