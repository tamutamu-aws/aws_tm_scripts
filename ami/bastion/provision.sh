#!/bin/bash
set -euo pipefail

readonly _ami_user_name=$1

CURDIR=$(cd $(dirname $0); pwd)
pushd ${CURDIR}



### Disable SELinux.
setenforce 0
sed -i.bak -e 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config


### General Settings.
yum -y install wget vim
wget http://ftp-srv2.kddilabs.jp/Linux/distributions/fedora/epel/7/x86_64/e/epel-release-7-9.noarch.rpm -P /tmp/
yum -y localinstall /tmp/epel-release-7-9.noarch.rpm
yum -y clean all
yum -y update

ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
rm -f /root/.ssh/authorized_key

### Disable service.
systemctl stop postfix.service
systemctl disable postfix.service

# chrony
sed -i.bak -e 's/\.centos\.pool\.ntp\.org/.jp.pool.ntp.org/g' \
  /etc/chrony.conf
systemctl restart chronyd


### cloud-init
# Setting locale.
sed -i.bak -e 's/^ - locale$/ - locale: ja_JP.UTF-8/' /etc/cloud/cloud.cfg

# In this script only, Setting Locale.
localectl set-locale LANG=ja_JP.UTF-8


### Execute scripts.
find /tmp/ -name '*.sh' -type f -print | xargs chmod +x


### Clamav
./clamav/clamav.sh

### awscli
yum -y install python-pip
pip install awscli


### Clean up
rm -rf /tmp/* /tmp/.[^.] /tmp/.??*


### Configure secure sshd_config
sed -i.bak -e 's/^#Protocol 2/Protocol 2/' \
           -e 's/^#RhostsRSAAuthentication no/RhostsRSAAuthentication no/' \
           -e 's/^#HostbasedAuthentication no/HostbasedAuthentication no/' \
           -e 's/^#PermitEmptyPasswords no/PermitEmptyPasswords no/' \
           -e 's/^PasswordAuthentication yes/PasswordAuthentication no/' \
           -e 's/^#RSAAuthentication yes/RSAAuthentication no/' \
           -e 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' \
           -e 's/^#PermitRootLogin yes/PermitRootLogin no/' \
           -e 's/^#AddressFamily any/AddressFamily inet/' \
  /etc/ssh/sshd_config


# Remove ami default user's password.
passwd -d ${_ami_user_name}

systemctl restart sshd.service

