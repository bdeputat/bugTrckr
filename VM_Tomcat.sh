#!/bin/bash
echo "Vagrant build scenario"

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

#<------------------ Create System Environment Variables ------------------>
Tomcat_user="tomcat_srv"
Tomcat_group="tomcat_gr"
SSH_User="tomcat"
SSH_User_Pass="tomcat"

# JAVA Environment Variables
JHOME_VAR="JAVA_HOME"
JHOME_VALUE="/usr/java/jre1.8.0_162"

# TOMCAT
THOME_VAR="CATALINA_HOME"
THOME_VALUE="/usr/java/apache-tomcat-7.0.85"

# Create new file with environmental variables
cat>/etc/profile.d/vars.sh<<EOF
${JHOME_VAR}=${JHOME_VALUE}
${THOME_VAR}=${THOME_VALUE}
PATH=$PATH:${JHOME_VALUE}/bin:${THOME_VALUE}/bin
EOF
source /etc/profile.d/vars.sh
echo "$(drawtext bold 2 "[ OK ]")" --- "Activating System Environment Variables"
#Activating System Environment Variables
cd  /etc/profile.d
source vars.sh
# <----- WorkSpace configurate ------>

# Create Install Environment Variables
#	WorkSpace
HOME_DIR="tomcat_install"
LOG_FILE=/$HOME_DIR/install.log

# Create WorkSpace 
cd /
mkdir ${HOME_DIR}
cd ${HOME_DIR}
echo "$(drawtext bold 2 "[ OK ]")" --- "File "$(drawtext bold 2 "$LOG_FILE")" successfully created"
echo START System --- $( date +"%H-%M-%S_%d-%m-%Y") > ${LOG_FILE} 
echo "$(drawtext bold 2 "START System")"  --- $( date +"%H-%M-%S_%d-%m-%Y")

# <----- Install Other Program ------>
#1 Update system and install tools
echo "Updating system... "
#yum update -y --nogpgcheck 2>>${LOG_FILE}
yum install -y mc wget net-tools --nogpgcheck 2>>${LOG_FILE}
echo "$(drawtext bold 2 "[ OK ]")" --- "System Updated"

#2. Install JAVA 1.8.0_162
#info: https://www.digitalocean.com/community/tutorials/how-to-install-java-on-centos-and-fedora
cd /${HOME_DIR} 
wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u162-b12/0da788060d494f5095bf8624735fa2f1/jre-8u162-linux-x64.rpm" 
rpm -ihv jre-8u162-linux-x64.rpm 2>>${LOG_FILE}
rm -f jre-8u162-linux-x64.rpm 2>>${LOG_FILE}
echo "$(drawtext bold 2 "[ OK ]")" --- ""$(drawtext bold 2 "JAVA 1.8.0_162")" successfully installed"


#3. Install apache-tomcat-8.5.27
#info: https://www.digitalocean.com/community/tutorials/how-to-install-apache-tomcat-8-on-centos-7
mkdir "${THOME_VALUE}"
wget http://apache.ip-connect.vn.ua/tomcat/tomcat-7/v7.0.85/bin/apache-tomcat-7.0.85.tar.gz
tar -zxvf apache-tomcat-7.0.85.tar.gz -C ${THOME_VALUE} --strip-components=1 2>>${LOG_FILE}
rm -f apache-tomcat-7.0.85.tar.gz 2>>${LOG_FILE}
echo "$(drawtext bold 2 "[ OK ]")" --- ""$(drawtext bold 2 "Apache-Tomcat")" successfully installed"


#Configure Virtual host on Tomcat
##Configure server.xml host on Tomcat 
#cd /${HOME_DIR}
#wget https://raw.githubusercontent.com/bdeputat/bugTrckr/master/bugTrckr_conf/server.xml
#mv server.xml ${THOME_VALUE}/conf/server.xml
#wget https://raw.githubusercontent.com/bdeputat/bugTrckr/master/bugTrckr_conf/tomcat-users.xml
#mv tomcat-users.xml ${THOME_VALUE}/conf/tomcat-users.xml


#Create Tomcat User
groupadd "${Tomcat_group}"
useradd -g "${Tomcat_group}" -d "${THOME_VALUE}" -p $(openssl passwd -1 "${SSH_User_Pass}") "${SSH_User}"
useradd -M -s /bin/nologin -g "${Tomcat_group}" -d "${THOME_VALUE}" "${Tomcat_user}"
echo "$(drawtext bold 2 "[ OK ]")" --- "System SSH_User_Pass successfully created"
#Give the tomcat group ownership over the entire installation directory:
cd "${THOME_VALUE}"
#Give the tomcat group ownership over the entire installation directory:
chgrp -R "${Tomcat_group}" "${HOME_DIR}"
chgrp -R "${Tomcat_group}" "${THOME_VALUE}"
#Next, give the tomcat group read access to the conf directory and all of its contents, and execute access to the directory itself:
chmod -R g+rwx conf/ webapps/ 
#Then make the tomcat user the owner of the webapps, work, temp, and logs directories:
chown -R "${Tomcat_user}" webapps/ work/ temp/ logs/ 

#Install Systemd Unit File
cd /etc/systemd/system/

# Create and the unit file tomcat.service
#info: https://stackoverflow.com/questions/40425012/tomcat-cannot-start-with-systemctl-on-centos7-2
cat>/etc/systemd/system/tomcat.service<<EOF
# Systemd unit file for tomcat
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=oneshot
Environment=JAVA_HOME=${JHOME_VALUE}
Environment=CATALINA_PID=${THOME_VALUE}/temp/tomcat.pid
Environment='CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC'
ExecStart=${THOME_VALUE}/bin/startup.sh
ExecStop=${THOME_VALUE}/bin/shutdown.sh
ExecReload=/usr/bin/kill -s HUP $MAINPID
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
echo "$(drawtext bold 2 "[ OK ]")" --- ""$(drawtext bold 2 "apache-tomcat-8.5.27")" successfully configurated"

#Install Apache mod on CentOS 7
yum clean all
yum -y install httpd
systemctl start httpd
systemctl enable httpd

cat>/etc/httpd/conf.d/tomcat.conf<<EOF
<VirtualHost *:80>
	ServerName bugtrckr.local
	ProxyPreserveHost On
	ProxyRequests Off
	ProxyPass / http://localhost:8080/
</VirtualHost>
EOF

/usr/sbin/setsebool httpd_can_network_connect true
service httpd restart
echo "$(drawtext bold 2 "[ OK ]")" --- ""$(drawtext bold 2 "apache-httpd")" successfully configurated"

#Add network hosts
wget https://raw.githubusercontent.com/bdeputat/bugTrckr/master/bugTrckr_conf/hosts.local
cat hosts.local >>/etc/hosts 2>>${LOG_FILE}
rm -f hosts.local 2>>${LOG_FILE}
echo "$(drawtext bold 2 "[ OK ]")" --- ""$(drawtext bold 2 "local.hosts")" successfully created" 2>>${LOG_FILE}

#Configure Firewalld
systemctl start firewalld 
systemctl enable firewalld

# Add tcp PORT 80 to firewall
echo "Allow 80 and 8080 port"
systemctl start firewalld
firewall-cmd --zone=public --add-port=22/tcp --permanent
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --zone=public --add-port=443/tcp --permanent
firewall-cmd --zone=public --add-port=8080/tcp --permanent
firewall-cmd --reload


#Now reload Systemd to load the Tomcat unit file:
systemctl daemon-reload
#Start the Tomcat service with this systemctl command:
systemctl start tomcat
#Tomcat service, so it starts on server boot, run this command:
systemctl enable tomcat

#Check that the service successfully started by typing:
systemctl status tomcat
echo "$(drawtext bold 2 "[ OK ]")" --- "$(drawtext bold 2 "All OPERATION DONE")" 2>>${LOG_FILE}
# <----- WorkSpace configurated ------>