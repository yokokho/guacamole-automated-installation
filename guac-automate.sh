#!/bin/bash

# Update sudo timestamp
sudo -v

# Ask for Tomcat username and password
read -p "Input your username for Tomcat: " tomcat_username
read -sp "Input your password for Tomcat: " tomcat_password
echo

# Ask for MySQL root password, Guacamole database name, username and password
read -sp "Enter MySQL root password: " mysql_root_password
echo
read -p "Enter Guacamole database name: " guacamole_db
read -p "Enter Guacamole database username: " guacamole_user
read -sp "Enter Guacamole database password: " guacamole_password
echo

# Ask for preferred Guacamole directory name
read -p "Enter your preferred path name for Guacamole: " guacamole_path
echo

# Update and upgrade the system
sudo apt update -y

# Check if Java is installed
if ! command -v java &> /dev/null
then
    echo "Java is not found. The script will now run apt install default-jdk."
    sudo apt install default-jdk -y
fi

# Install expect if not already installed
if ! command -v expect &> /dev/null
then
    sudo apt install expect -y
fi

# Install necessary packages
sudo apt install build-essential libcairo2-dev libjpeg-turbo8-dev \
    libpng-dev libtool-bin libossp-uuid-dev libvncserver-dev \
    freerdp2-dev libssh2-1-dev libtelnet-dev libwebsockets-dev \
    libpulse-dev libvorbis-dev libwebp-dev libssl-dev \
    libpango1.0-dev libswscale-dev libavcodec-dev libavutil-dev \
    libavformat-dev -y

# Create directory and group/user for Tomcat
sudo mkdir /opt/tomcat
sudo groupadd tomcat
sudo useradd -s /bin/false -g tomcat -d /opt/tomcat tomcat

# Download and extract Tomcat
cd /tmp
wget https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.89/bin/apache-tomcat-9.0.89.tar.gz
sudo tar -xvzf apache-tomcat-9.0.89.tar.gz -C /opt/tomcat --strip-components=1

# Return to the original directory
cd -

# Change ownership and permissions of the Tomcat directory
sudo chown -RH tomcat: /opt/tomcat/
sudo sh -c 'chmod +x /opt/tomcat/bin/*.sh'

# Get the version of Java being used
JAVA_VERSION=$(sudo update-java-alternatives -l | awk '{print $3}' | awk -F'/' '{print $5}')

# Create a systemd configuration file for Tomcat
cat << EOF | sudo tee /etc/systemd/system/tomcat.service
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking
User=tomcat
Group=tomcat
Environment="JAVA_HOME=/usr/lib/jvm/$JAVA_VERSION"
Environment="JAVA_OPTS=-Djava.security.egd=file:///dev/urandom -Djava.awt.headless=true"
Environment="CATALINA_BASE=/opt/tomcat"
Environment="CATALINA_HOME=/opt/tomcat"
Environment="CATALINA_PID=/opt/tomcat/temp/tomcat.pid"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"
ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

[Install]
WantedBy=multi-user.target
EOF

# Reload the daemon, start, and enable Tomcat
sudo systemctl daemon-reload
sudo systemctl start tomcat
sudo systemctl enable tomcat

# Check the status of Tomcat
if systemctl is-active --quiet tomcat
then
    echo "Tomcat has been run successfully."
fi

# Add the user to tomcat-users.xml
sudo sed -i "/<\/tomcat-users>/i \  <role rolename=\"manager-gui\"/>\n  <role rolename=\"manager-status\"/>\n  <user username=\"$tomcat_username\" password=\"$tomcat_password\" roles=\"manager-gui, manager-status\"/>" /opt/tomcat/conf/tomcat-users.xml

# Modify context.xml files
for context_file in /opt/tomcat/webapps/manager/META-INF/context.xml /opt/tomcat/webapps/host-manager/META-INF/context.xml
do
    sudo sed -i 's/<Context antiResourceLocking="false" privileged="true" >/<Context antiResourceLocking="false" privileged="true" >\n<!--/' $context_file
    sudo sed -i 's/<\/Context>/-->\n<\/Context>/' $context_file
done

# Download and extract Guacamole server
wget https://archive.apache.org/dist/guacamole/1.5.5/source/guacamole-server-1.5.5.tar.gz
tar -xvf guacamole-server-1.5.5.tar.gz 
cd guacamole-server-1.5.5

# Configure, make and install Guacamole server
sudo ./configure --with-init-dir=/etc/init.d --enable-allow-freerdp-snapshots || sudo ./configure --with-init-dir=/etc/init.d --enable-allow-freerdp-snapshots --disable-guacenc
sudo make
sudo make install
sudo ldconfig

# Start and enable Guacamole daemon
sudo systemctl daemon-reload
sudo systemctl start guacd
sudo systemctl enable guacd

# Create necessary directories
sudo mkdir -p /etc/guacamole/extensions
sudo mkdir -p /etc/guacamole/lib

# Download Guacamole WAR file
wget https://archive.apache.org/dist/guacamole/1.5.5/binary/guacamole-1.5.5.war

# Move Guacamole WAR file to Tomcat webapps directory with user defined path
sudo mv guacamole-1.5.5.war /opt/tomcat/webapps/${guacamole_path}.war

# Set ownership for Tomcat webapps directory
sudo chown -R tomcat:tomcat /opt/tomcat/webapps/

# Install MariaDB server
sudo apt install mariadb-server -y

# Secure MariaDB installation
# Use expect to automate MySQL secure installation
SECURE_MYSQL=$(expect -c "
set timeout 10
spawn mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"\r\"
expect \"Switch to unix_socket authentication?\"
send \"n\r\"
expect \"Change the root password?\"
send \"y\r\"
expect \"New password:\"
send \"$mysql_root_password\r\"
expect \"Re-enter new password:\"
send \"$mysql_root_password\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")

echo "$SECURE_MYSQL"
 

# Download and install MySQL Connector/J
wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-8.0.26.tar.gz
tar -xf mysql-connector-java-8.0.26.tar.gz
sudo cp mysql-connector-java-8.0.26/mysql-connector-java-8.0.26.jar /etc/guacamole/lib/

# Download and install Guacamole JDBC authentication
wget https://archive.apache.org/dist/guacamole/1.5.5/binary/guacamole-auth-jdbc-1.5.5.tar.gz
tar -xf guacamole-auth-jdbc-1.5.5.tar.gz
sudo mv guacamole-auth-jdbc-1.5.5/mysql/guacamole-auth-jdbc-mysql-1.5.5.jar /etc/guacamole/extensions/

# Create Guacamole database and user
mysql -u root -p$mysql_root_password <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '$mysql_root_password';
CREATE DATABASE $guacamole_db;
CREATE USER '$guacamole_user'@'localhost' IDENTIFIED BY '$guacamole_password';
GRANT SELECT,INSERT,UPDATE,DELETE ON $guacamole_db.* TO '$guacamole_user'@'localhost';
FLUSH PRIVILEGES;
EOF

# Import Guacamole schema
cd guacamole-auth-jdbc-1.5.5/mysql/schema
cat *.sql | mysql -u root -p$mysql_root_password $guacamole_db

# Create Guacamole properties file
cat << EOF | sudo tee /etc/guacamole/guacamole.properties
# MySQL properties 
mysql-hostname: 127.0.0.1 
mysql-port: 3306 
mysql-database: $guacamole_db 
mysql-username: $guacamole_user 
mysql-password: $guacamole_password
EOF

# Restart services
sudo systemctl restart tomcat guacd mysql

# Check the status of UFW and set access to port 8080 if necessary
if sudo ufw status | grep -q inactive
then
    echo "No UFW detected, you can now access Tomcat on your browser via http://server_ip:8080."
else
    if ! sudo ufw status | grep -q 8080
    then
        echo "UFW has blocked port 8080/tcp on your server. The script will now try to allow the port."
        sudo ufw allow 8080/tcp
        echo "UFW rules have been changed. UFW has allowed port 8080/tcp on your server."
    fi
fi
