#!/bin/bash
set -euo pipefail

declare -r aws_s3_bucket=$1


CURDIR=$(cd $(dirname $0); pwd)
pushd ${CURDIR}


### Disable SELinux.
setenforce 0
sed -i.bak -e 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config


### Disable service.
systemctl stop postfix.service
systemctl disable postfix.service


### General Settings.
ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# Add dev group, for sudo group.
groupadd dev

# Configure Group of possible to command, 'sudo'.
cat << EOT > /etc/sudoers.d/dev-users
%dev ALL=(ALL) NOPASSWD:ALL
EOT

# Add create_user.sh
mkdir -p /opt/scripts/system/users/

cat << 'EOT' > /opt/scripts/system/users/create_user.sh
#!/bin/bash
declare -r USER_NAME=$1

useradd ${USER_NAME} -G dev
echo ${USER_NAME} | passwd --stdin ${USER_NAME}
EOT
chmod 700 /opt/scripts/system/users/create_user.sh

# chrony
sed -i.bak -e 's/\.centos\.pool\.ntp\.org/.jp.pool.ntp.org/g' \
  /etc/chrony.conf
systemctl restart chronyd


### cloud-init
# Setting locale.
sed -i.bak -e 's/^ - locale$/ - locale: ja_JP.UTF-8/' /etc/cloud/cloud.cfg

# In this script only, Setting Locale.
localectl set-locale LANG=ja_JP.UTF-8


### Configure secure sshd_config

## Enable ssh_pwauth setting by cloud-init.
sed -i.bak -e 's/^ssh_pwauth:.*$/ssh_pwauth:   yes/' \
           -e 's/lock_passwd:.*true/lock_passwd: false/' \
  /etc/cloud/cloud.cfg
  

sed -i.bak -e 's/^#Protocol 2/Protocol 2/' \
           -e 's/^#RhostsRSAAuthentication no/RhostsRSAAuthentication no/' \
           -e 's/^#HostbasedAuthentication no/HostbasedAuthentication no/' \
           -e 's/^#PermitEmptyPasswords no/PermitEmptyPasswords no/' \
           -e 's/^PasswordAuthentication no/PasswordAuthentication yes/' \
           -e 's/^#RSAAuthentication yes/RSAAuthentication no/' \
           -e 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' \
           -e 's/^#PermitRootLogin yes/PermitRootLogin no/' \
           -e 's/^#AddressFamily any/AddressFamily inet/' \
  /etc/ssh/sshd_config

systemctl restart sshd.service


### Execute scripts.
find /tmp/ -name '*.sh' -type f -print | xargs chmod +x


### Execute Install scripts.
./common-dev/common-dev.sh
./aws/aws.sh


### s3 mount, when System startup.
mkdir -p /mnt/s3/${aws_s3_bucket}

mkdir -p /opt/scripts/system/s3/

cat << EOL > /opt/scripts/system/s3/s3mount.sh
#!/bin/bash
sudo goofys -o allow_other --dir-mode 07777 --file-mode 0777 $aws_s3_bucket /mnt/s3/${aws_s3_bucket}
EOL

chmod a+x /opt/scripts/system/s3/s3mount.sh
/opt/scripts/system/s3/s3mount.sh

# Mount S3 whene system startup.
chmod a+x /etc/rc.local

cat << EOL >> /etc/rc.local

### Mount S3.
/opt/scripts/system/s3/s3mount.sh
EOL


### Install..
./clamav/clamav.sh
./java-dev/jdk.sh
./java-dev/maven-3.sh
./java-dev/gradle.sh


### Clean up
rm -rf /tmp/* /tmp/.[^.] /tmp/.??*

popd
