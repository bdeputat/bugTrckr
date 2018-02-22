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
# JAVA Environment Variables
JHOME_VAR="JAVA_HOME"
JHOME_VALUE="/usr/java/jdk1.8.0_162"
JRE_VAR="JRE_HOME"
JRE_VALUE="/usr/java/jdk1.8.0_162/jre"

# MAVEN
MHOME_VAR="MAVEN_HOME"
MHOME_VALUE="/usr/java/apache-maven-3.5.2"

# JENKINS
JENHOME_VAR="JENKINS_HOME"
JENHOME_VALUE="/usr/jenkins"
# FOLDER AND FILE ENVIRONMENTAL
FILEFOLDER="/etc/profile.d"
FILENAME="vars.sh"

# Create new file with environmental variables
touch ${FILENAME}
echo "$(drawtext bold 2 "[ OK ]")" --- "Creating scenario file: $(drawtext bold 2 ${FILENAME})" 

# Writting lines to the file
echo "Writting scenario to the file ${FILENAME}"

echo   "${JHOME_VAR}=${JHOME_VALUE}" > ${FILENAME}
echo   "${JRE_VAR}=${JRE_VALUE}" >> ${FILENAME}
echo "$(drawtext bold 2 "[ OK ]")" --- "Writting $(drawtext bold 2 ${JHOME_VAR}) variable"

echo   "${MHOME_VAR}=${MHOME_VALUE}" >> ${FILENAME}
echo "$(drawtext bold 2 "[ OK ]")" --- "Writting $(drawtext bold 2 ${MHOME_VAR}) variable"

echo   "${JENHOME_VAR}=${JENHOME_VALUE}" >> ${FILENAME}
echo "$(drawtext bold 2 "[ OK ]")" --- "Writting $(drawtext bold 2 ${JENHOME_VAR}) variable"

# Add ALL bin folder to the PATH environmental variable
echo "PATH=$PATH:${JHOME_VALUE}/bin:${JRE_VALUE}/bin:${MHOME_VALUE}/bin:${JENHOME_VALUE}" >> ${FILENAME}
echo "$(drawtext bold 2 "[ OK ]")" ---  "Changing $(drawtext bold 2 "PATH") variable"
# Copying file with variables to the specific folder
mv ${FILENAME} $FILEFOLDER/${FILENAME}
echo "$(drawtext bold 2 "[ OK ]")" --- "Moving file $(drawtext bold 2 ${FILENAME}) to the $(drawtext bold 2 $FILEFOLDER)"


#Activating System Environment Variables
cd  /etc/profile.d
source vars.sh

# <----- WorkSpace configurate ------>


# Create Install Environment Variables
#	WorkSpace
HOME_DIR="jenkins_install"
LOG_FILE=/$HOME_DIR/scenario.log

cd /
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

#1. Install wget GIT
cd /${HOME_DIR}
yum install -y mc wget net-tools git firewalld --nogpgcheck 2>>${LOG_FILE}
echo "$(drawtext bold 2 "[ OK ]")" --- ""$(drawtext bold 2 "wget, GIT")" successfully installed"

#2. Install JAVA 1.8.0_162
#info: https://www.digitalocean.com/community/tutorials/how-to-install-java-on-centos-and-fedora
cd /${HOME_DIR} 
wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u162-b12/0da788060d494f5095bf8624735fa2f1/jdk-8u162-linux-x64.rpm" 
rpm -ihv jdk-8u162-linux-x64.rpm 2>>${LOG_FILE}
rm -f jdk-8u162-linux-x64.rpm  2>>${LOG_FILE}
echo "$(drawtext bold 2 "[ OK ]")" --- ""$(drawtext bold 2 "JAVA")" successfully installed"

#3. Install Apache-Maven
cd /usr/java 
#info: https://tecadmin.net/install-apache-maven-on-centos/
wget http://www-eu.apache.org/dist/maven/maven-3/3.5.2/binaries/apache-maven-3.5.2-bin.tar.gz
tar -zxvf apache-maven-3.5.2-bin.tar.gz 2>>${LOG_FILE}
rm -f apache-maven-3.5.2-bin.tar.gz 2>>${LOG_FILE}
ln -sf ${MAVEN_HOME}/bin/mvn /usr/bin/mvn

echo "$(drawtext bold 2 "[ OK ]")" --- ""$(drawtext bold 2 "Apache-Maven")" successfully installed"
#add non root user
useradd -p $(openssl passwd -1 jenkins) jenkins
#4. Step 1 — Installing Jenkins
#Installing from the WAR File
#info: https://www.digitalocean.com/community/tutorials/how-to-set-up-jenkins-for-continuous-development-integration-on-centos-7
sudo mkdir ${JENKINS_HOME}
cd ${JENKINS_HOME}
#Download the Jenkins WAR file to the server and run it 
wget http://mirrors.jenkins-ci.org/war/latest/jenkins.war


#When you're ready, start Jenkins via Java:
#java -jar jenkins.war

#!!!!!!!!!!!!!!!!!!!!Please use the following password to proceed to installation:
#1bc2729f77af47309afc16a3d1af0abc

#Step 2 — Running Jenkins as a Service
#First, make sure the WAR file you’ve downloaded is sitting in a location convenient for long-term storage and use:
#cp jenkins.war ${JENHOME_VALUE}/jenkins.war
#Then, go to your /etc/systemd/system/ directory, and create a new file called jenkins.service. 
cd /etc/systemd/system/

sudo touch jenkins.service
sudo echo   "[Unit]" > jenkins.service
sudo echo   "Description=Jenkins Service" >> jenkins.service
sudo echo   "After=network.target" >> jenkins.service
sudo echo   "[Service]" >> jenkins.service
sudo echo   "Type=simple" >> jenkins.service
sudo echo   "User=root" >> jenkins.service
sudo echo   "ExecStart=/usr/bin/java -jar ${JENKINS_HOME}/jenkins.war" >> jenkins.service
sudo echo   "Restart=on-abort" >> jenkins.service
sudo echo   "[Install]" >> jenkins.service
sudo echo   "WantedBy=multi-user.target" >> jenkins.service
#Once your file is created and saved, you should be able to start up your new Jenkins service!
sudo systemctl daemon-reload
#You should now be able to start Jenkins as a service:
sudo systemctl start jenkins.service
#Once the service has started, you can check its status:
sudo systemctl status jenkins.service
sudo systemctl enable jenkins.service
sudo echo "$(drawtext bold 2 "[ OK ]")" --- ""$(drawtext bold 2 "JENKINS")" successfully installed"
#Configure Firewalld
sudo systemctl start firewalld 
sudo systemctl enable firewalld

su exit
# Add tcp PORT 80 to firewall
echo "Allow 80 and 8080 port"
systemctl start firewalld
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --zone=public --add-port=8080/tcp --permanent
firewall-cmd --zone=public --add-port=22/tcp --permanent
firewall-cmd --reload
cd ${HOME_DIR}
wget https://raw.githubusercontent.com/bdeputat/bugTrckr/master/bugTrckr_conf/hosts.local
cat hosts.local >>/etc/hosts 2>>${LOG_FILE}
rm -f hosts.local 2>>${LOG_FILE}
echo "$(drawtext bold 2 "[ OK ]")" --- ""$(drawtext bold 2 "local.hosts")" successfully created" 2>>${LOG_FILE}



# <----- WorkSpace configurated ------>

# <----- WorkSpace configurated ------>
