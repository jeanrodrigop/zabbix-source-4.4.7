#!/bin/bash
## ---------------------------------------------------------------------- ##
##  Automate installation of Zabbix agent 4.4.7 from source on Debian 12
##  Autor: Jean Rodrigo
## ---------------------------------------------------------------------- ##
##  HOW TO USE?
##    
##  download script, give execution permission and run
##  
##  $ chmod +x zabbix-source-4.4.7.sh
##  $ ./zabbix-source-4.4.7.sh
## ----------------------------- VARIABLES ------------------------------ ##

set -e

# Links
SOURCE_LINK="https://cdn.zabbix.com/zabbix/sources/oldstable/4.4/zabbix-4.4.7.tar.gz"

# Variables
SOURCE_FILE="zabbix-4.4.7.tar.gz"
SOURCE_DIR="zabbix-4.4.7"


## Functions
# Install dependencies
fix_install() {
    echo -e "\n< ============= INSTALLING DEPENDENCIES ============= >\n"
    apt install -y libpcre3-dev cmake
}

# Download source file 
source_download() {
    echo -e "\n< ============= DOWNLOADING SOURCES ============= >\n"
    wget $SOURCE_LINK
}

# Extract file 
extract_source() {
    echo -e "\n< ============= EXTRACTING SOURCES ============= >\n"
    tar -xvf $SOURCE_FILE
}

# Create user account
create_user() {
    addgroup --system --quiet zabbix
    adduser --quiet --system --disabled-login --ingroup zabbix --home /var/lib/zabbix --no-create-home zabbix
}

# Configure sources for a Zabbix agent
config_source() {
    echo -e "\n< ============= SOURCE CONFIGURATION ============= >\n"
    cd $SOURCE_DIR;./configure --enable-agent --sysconfdir=/etc/zabbix;cd ~/
}

# Make and install
make_install() {
    echo -e "\n< ============= BUILD ZABBIX FROM SOURCES ============= >\n"
    cd $SOURCE_DIR;make install;cd ~/
}

# Create directories
create_directories() {
    mkdir /var/run/zabbix && chmod 777 /var/run/zabbix
    mkdir /var/log/zabbix && chmod 777 /var/log/zabbix
    
    clear
}

# Zabbix configuration
zabbix_config() {
    echo -e "\n< ============= ZABBIX CONFIGURATION ============= >\n"
    # Request user information
    read -p "Digite o IP do proxy: " PROXY_IP
    read -p "Digite o nome do host e código do cliente (Hostname_CLIENTE): " HOST_CLIENT
    if [ "$CHANGE_PORT" == "S" ] || [ "$CHANGE_PORT" == "s" ]; then
        read -p "Digite o número da porta: " LISTEN_PORT
        sed -i "s/# ListenPort=10050/ListenPort=$LISTEN_PORT/" /etc/zabbix/zabbix_agentd.conf
    fi

    # Apply configurations
    sed -i "s/# PidFile=\/tmp\/zabbix_agentd.pid/PidFile=\/var\/run\/zabbix\/zabbix_agentd.pid/" /etc/zabbix/zabbix_agentd.conf
    sed -i "s/LogFile=\/tmp\/zabbix_agentd.log/LogFile=\/var\/log\/zabbix\/zabbix_agentd.log/" /etc/zabbix/zabbix_agentd.conf
    sed -i "s/# LogFileSize=1/LogFileSize=10/" /etc/zabbix/zabbix_agentd.conf
    sed -i "s/# EnableRemoteCommands=0/EnableRemoteCommands=1/" /etc/zabbix/zabbix_agentd.conf
    sed -i "s/Server=127\.0\.0\.1/Server=$PROXY_IP/" /etc/zabbix/zabbix_agentd.conf
    sed -i "s/# StartAgents=3/StartAgents=5/" /etc/zabbix/zabbix_agentd.conf
    sed -i "s/ServerActive=127\.0\.0\.1/ServerActive=$PROXY_IP/" /etc/zabbix/zabbix_agentd.conf
    sed -i "s/Hostname=Zabbix\ server/Hostname=$HOST_CLIENT/" /etc/zabbix/zabbix_agentd.conf
    sed -i "s/# Timeout=3/Timeout=30/" /etc/zabbix/zabbix_agentd.conf
}

# Create systemd configuration
# Environment="CONFFILE=/etc/zabbix/zabbix_agentd.conf"
systemd_config() {
    cat >/usr/lib/systemd/system/zabbix-agent.service<< EOF
[Unit]
Description=Zabbix Agent
After=syslog.target
After=network.target

[Service]
Environment="CONFFILE=/etc/zabbix/zabbix_agentd.conf"
Type=forking
Restart=on-failure
PIDFile=/var/run/zabbix/zabbix_agentd.pid
KillMode=control-group
ExecStart=/usr/local/sbin/zabbix_agentd -c \$CONFFILE
ExecStop=/bin/kill -SIGTERM \$MAINPID
RestartSec=10s
User=zabbix
Group=zabbix

[Install]
WantedBy=multi-user.target
EOF
}

# Reload daemon and start service
reload_daemon() {
    systemctl daemon-reload
    systemctl restart zabbix-agent
    systemctl enable zabbix-agent
}

# Execute script functions
fix_install
source_download
extract_source
create_user
config_source
make_install
create_directories
zabbix_config
systemd_config
reload_daemon

