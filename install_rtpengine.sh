#!/bin/bash

#--------------------------------------------
# Installation of RTPengine on debian 11 (Bullseye)
#--------------------------------------------

#set the ip address
server_address=45.75.29.77

#----------------------------------------------------
# Disable password authentication
#----------------------------------------------------
sudo sed -i 's/#ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config 
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo service sshd restart

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n============= Update Server ================"
sudo apt update && sudo apt -y upgrade
sudo apt autoremove -y

sudo apt install -y nano

#-----------------------------------------------
# Installation of FFMPEG v4
#----------------------------------------------
# Install FFmpeg 4 using External Repository
sudo apt install -y ffmpeg

#--------------------------------------------
# Install required libraries
#--------------------------------------------
        apt remove -y ufw apparmor
        apt install -y firewalld
        apt install -y libncurses-dev
        apt install -y git logrotate rsyslog 
        apt install -y libbcg729-0 libbcg729-dev
        apt install -y iptables-dev
        apt install -y libcurl4-openssl-dev
        apt install -y libpcre3-dev libxmlrpc-core-c3-dev
        apt install -y markdown
        apt install -y libglib2.0-dev
        apt install -y libavcodec-dev
        apt install -y libevent-dev
        apt install -y libhiredis-dev
        apt install -y libjson-glib-dev libpcap0.8-dev libpcap-dev libssl-dev
        apt install -y libavfilter-dev
        apt install -y libavformat-dev
        apt install -y libmariadbclient-dev libmariadb-dev
        apt install -y default-libmysqlclient-dev
        apt install -y module-assistant
        apt install -y debhelper
        apt install -y nfs-common libb-hooks-op-check-perl
        apt install -y dpkg-dev
        apt install -y dkms
        apt install -y unzip wget git curl
        apt install -y libavresample-dev
        apt install -y linux-headers-$(uname -r)
        apt install -y python3 python3-dev python3-websockets
        apt install -y gperf libbencode-perl libcrypt-openssl-rsa-perl libcrypt-rijndael-perl libdigest-crc-perl libdigest-hmac-perl \
        libio-multiplex-perl libio-socket-inet6-perl libnet-interface-perl libsocket6-perl libspandsp-dev libsystemd-dev libwebsockets-dev \
        libavutil-dev libiptc-dev libmosquitto-dev libjson-perl libxtables-dev libtest2-suite-perl
        
        # other dependencies
        apt install -y cmake libswresample-dev zlib1g-dev build-essential keyutils libnfsidmap2 libexporter-tidy-perl \
        rpcbind libtirpc3 libconfig-tiny-perl dh-autoreconf libiptcdata-dev libarchive13 
    
#--------------------------------------------
# Download rtpengine from source
#--------------------------------------------
cd /usr/src
git clone https://github.com/sipwise/rtpengine.git
cd rtpengine

echo "########## G729 Installation ################"

VER=1.0.4
curl -s https://codeload.github.com/BelledonneCommunications/bcg729/tar.gz/$VER > bcg729_$VER.orig.tar.gz &&
tar zxf bcg729_$VER.orig.tar.gz &&
cd bcg729-$VER &&
git clone https://github.com/ossobv/bcg729-deb.git debian &&
dpkg-buildpackage -us -uc -sa &&
cd .. &&
dpkg -i libbcg729-*.deb

########################################################

# Now let’s check the RTPengine dependencies again:
dpkg-checkbuilddeps

# If you get an empty output you’re good to start building the packages:
dpkg-buildpackage -us -uc -sa &&
cd .. &&

dpkg -i ./ngcp-rtpengine-iptables_*.deb
dpkg -i ./ngcp-rtpengine-daemon_*.deb
dpkg -i ./ngcp-rtpengine-kernel-dkms_*.deb
dpkg -i ./ngcp-rtpengine-kernel-source_*.deb
dpkg -i ./ngcp-rtpengine-recording-daemon_*.deb
dpkg -i ./ngcp-rtpengine-utils_*.deb
dpkg -i ./ngcp-rtpengine_*.deb

# Getting it Running:
cp /etc/rtpengine/rtpengine.sample.conf  /etc/rtpengine/rtpengine.conf

# We’ll uncomment the interface line and set the IP to the IP we’ll be listening on
sudo sed -i 's/RUN_RTPENGINE = no/RUN_RTPENGINE = yes/' /etc/rtpengine/rtpengine.conf 
# sudo echo -e 'interface=$server_address' >> /etc/rtpengine/rtpengine.conf
# sudo sed -i 's/# recording-dir = /var/spool/rtpengine/recording-dir = /var/spool/rtpengine/' /etc/rtpengine/rtpengine.conf
sudo sed -i 's/# recording-method = proc/recording-method = proc/' /etc/rtpengine/rtpengine.conf
sudo sed -i 's/# recording-format = raw/recording-format = raw/' /etc/rtpengine/rtpengine.conf
sudo sed -i 's/# log-level = 6/log-level = 7/' /etc/rtpengine/rtpengine.conf
sudo sed -i 's/# log-facility = daemon/log-facility = local1/' /etc/rtpengine/rtpengine.conf
sudo sed -i 's/# log-facility-cdr = local0/log-facility-cdr = local1/' /etc/rtpengine/rtpengine.conf
sudo sed -i 's/# log-facility-rtcp = local1/log-facility-rtcp = local1/' /etc/rtpengine/rtpengine.conf

# Edit ngcp-rtpengine-daemon and ngcp-rtpengine-recording-daemon files:
sudo sed -i 's/RUN_RTPENGINE=no/RUN_RTPENGINE=yes/' /etc/default/ngcp-rtpengine-daemon

sudo sed -i 's/RUN_RTPENGINE=no/RUN_RTPENGINE=yes/' /etc/default/ngcp-rtpengine-recording-daemon
sudo sed -i 's/RUN_RTPENGINE_RECORDING=no/RUN_RTPENGINE_RECORDING=yes/' /etc/default/ngcp-rtpengine-recording-daemon

cp /etc/rtpengine/rtpengine-recording.sample.conf /etc/rtpengine/rtpengine-recording.conf

systemctl enable ngcp-rtpengine-daemon.service 
systemctl restart ngcp-rtpengine-daemon.service 
systemctl status ngcp-rtpengine-daemon.service

systemctl enable ngcp-rtpengine-recording-daemon.service 
systemctl restart ngcp-rtpengine-recording-daemon.service 
systemctl status ngcp-rtpengine-recording-daemon.service

systemctl enable ngcp-rtpengine-recording-nfs-mount.service
systemctl restart ngcp-rtpengine-recording-nfs-mount.service
systemctl status ngcp-rtpengine-recording-nfs-mount.service

ps -ef | grep rtpengine

# Enable and start firewalld if not already running
systemctl enable firewalld
systemctl start firewalld

# Setup Firewall rules for RTPEngine
firewall-cmd --zone=public --add-port=30000-40000/udp --permanent
firewall-cmd --zone=public --add-port=5060-5066/udp --permanent
firewall-cmd --zone=public --add-port=5060-5066/tcp --permanent
firewall-cmd --reload

