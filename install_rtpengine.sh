#!/bin/bash

#--------------------------------------------
# Installation of RTPengine on debian 10 
#--------------------------------------------

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
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y

sudo apt install -y vim

# disable vim visual mode
echo "set mouse-=a" >> ~/.vimrc

#-----------------------------------------------
# Installation of FFMPEG v4
#----------------------------------------------
# Install FFmpeg 4 using External Repository
sudo apt install -y gnupg gnupg1 gnupg2
add-apt-repository ppa:jonathonf/ffmpeg-4
sudo apt update

sudo apt install -y ffmpeg
ffmpeg -version

#--------------------------------------------
# Install required libraries
#--------------------------------------------
sudo apt install -y git \
                    dpkg-dev \
                    cmake \
                    unzip \
                    wget \
                    debhelper \
                    default-libmysqlclient-dev \
                    gperf \
                    iptables-dev \
                    libavcodec-dev \
                    libavfilter-dev \
                    libavformat-dev \
                    libavutil-dev \
                    libbencode-perl \
                    libcrypt-openssl-rsa-perl \
                    libcrypt-rijndael-perl \
                    libcurl4-openssl-dev \
                    libdigest-crc-perl \
                    libdigest-hmac-perl \
                    libevent-dev \
                    libglib2.0-dev \
                    libhiredis-dev \
                    libio-multiplex-perl \
                    libio-socket-inet6-perl \
                    libiptc-dev \
                    libjson-glib-dev \
                    libnet-interface-perl \
                    libpcap0.8-dev \
                    libpcap-dev \
                    libhiredis-dev \
                    libpcre3-dev \
                    libsocket6-perl \
                    libspandsp-dev \
                    libssl-dev \
                    libevent-dev \
                    libswresample-dev \
                    libsystemd-dev \
                    libxmlrpc-core-c3-dev \
                    markdown \
                    curl \
                    wget \
                    zlib1g-dev \
                    dkms \
                    build-essential \
                    module-assistant \
                    libwebsockets-dev \
                    keyutils \
                    libnfsidmap2 \
                    nfs-common \
                    rpcbind \
                    libtirpc3 \
                    libconfig-tiny-perl \
                    dh-autoreconf \
                    libio-multiplex-perl \
                    libglib2.0-dev 

#--------------------------------------------
# Download rtpengine from source
#--------------------------------------------
cd /usr/src
git clone https://github.com/sipwise/rtpengine.git
cd rtpengine

echo "########## G729 Installation ################"

VER=1.0.4
curl https://codeload.github.com/BelledonneCommunications/bcg729/tar.gz/$VER >bcg729_$VER.orig.tar.gz
tar zxf bcg729_$VER.orig.tar.gz 
cd bcg729-$VER 
git clone https://github.com/ossobv/bcg729-deb.git debian 
dpkg-buildpackage -us -uc -sa
cd ..
dpkg -i libbcg729-*.deb

########################################################

# Now let’s check the RTPengine dependencies again:
dpkg-checkbuilddeps

# If you get an empty output you’re good to start building the packages:
dpkg-buildpackage 

cd ..

dpkg -i ngcp-rtpengine-daemon_*.deb

# Getting it Running:
cp /etc/rtpengine/rtpengine.sample.conf  /etc/rtpengine/rtpengine.conf

# We’ll uncomment the interface line and set the IP to the IP we’ll be listening on
sudo sed -i 's/# interface = 123.234.345.456/interface = 136.244.67.56/'   /etc/rtpengine/rtpengine.conf

# Edit ngcp-rtpengine-daemon and ngcp-rtpengine-recording-daemon files:
sudo sed -i 's/RUN_RTPENGINE=no/RUN_RTPENGINE=yes/' /etc/default/ngcp-rtpengine-daemon

dpkg -i ngcp-rtpengine-iptables_*.deb
dpkg -i ngcp-rtpengine-kernel-dkms_*.deb
dpkg -i ngcp-rtpengine-kernel-source_*.deb
dpkg -i ngcp-rtpengine-recording-daemon_*.deb

sudo sed -i 's/RUN_RTPENGINE_RECORDING=no/RUN_RTPENGINE_RECORDING=yes/' /etc/default/ngcp-rtpengine-recording-daemon

cp /etc/rtpengine/rtpengine-recording.sample.conf /etc/rtpengine/rtpengine-recording.conf
vim /etc/rtpengine/rtpengine-recording.conf
mkdir /var/spool/rtpengine

dpkg -i ngcp-rtpengine-utils_*.deb
dpkg -i ngcp-rtpengine_*.deb

systemctl enable ngcp-rtpengine-daemon.service 
systemctl enable ngcp-rtpengine-recording-daemon.service 
systemctl enable ngcp-rtpengine-recording-nfs-mount.service

systemctl restart ngcp-rtpengine-daemon.service 
systemctl restart ngcp-rtpengine-recording-daemon.service 
systemctl restart ngcp-rtpengine-recording-nfs-mount.service

ps -ef | grep rtpengine


