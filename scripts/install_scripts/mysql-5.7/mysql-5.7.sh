#!/bin/bash
set -euo pipefail

echo "Install Mysql." 

CURDIR=$(cd $(dirname $0); pwd)
pushd ${CURDIR}

. ./var.conf


### Install
yum -y localinstall https://dev.mysql.com/get/mysql57-community-release-el7-9.noarch.rpm
yum -y install mysql-community-server
mysqld --initialize-insecure --user=mysql
systemctl enable mysqld.service
systemctl restart mysqld.service


### Secure Settings.
sed  -e "s/#MYSQL_ROOT_PASS#/${MYSQL_ROOT_PASS}/g" \
 ./conf/mysql_secure_installation.sql.tmpl > ./conf/mysql_secure_installation.sql

mysql -uroot < ./conf/mysql_secure_installation.sql
rm -f ./conf/mysql_secure_installation.sql

popd
