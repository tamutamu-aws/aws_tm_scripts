#!/bin/bash
set -euo pipefail
 
echo "Install Jenkins2." 
 
CURDIR=$(cd $(dirname $0); pwd)
pushd ${CURDIR}

. ./var.conf
 
 
### Install
wget http://mirrors.jenkins.io/war-stable/latest/jenkins.war -P "${TOMCAT_HOME}"/webapps/
 
 
### Apache Proxy
cp ./conf/jenkins2_proxy.conf /etc/httpd/conf.d/
 
 
### Configure Service
cp /etc/sysconfig/tomcat8{,.orig}
gawk -f add_env2service.awk /etc/sysconfig/tomcat8.orig \
  > /etc/sysconfig/tomcat8
 

### init.groovy.d
mkdir -p ${TOMCAT_HOME}/.jenkins/init.groovy.d/

sed -e "s/#ADMIN_USER#/${ADMIN_USER}/" -e "s/#ADMIN_PASS#/${ADMIN_PASS}/" \
  ./conf/init.groovy.d/00-basic-security.groovy.tmpl \
  > ${TOMCAT_HOME}/.jenkins/init.groovy.d/00-basic-security.groovy

\cp -f ./conf/init.groovy.d/10-install-plugin.groovy \
   ${TOMCAT_HOME}/.jenkins/init.groovy.d/

chown tomcat:tomcat ${TOMCAT_HOME}/.jenkins -R
 

systemctl daemon-reload
systemctl restart tomcat8.service
systemctl restart httpd.service

popd
