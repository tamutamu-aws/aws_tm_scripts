#!/bin/bash
set -euo pipefail

echo "Install Oracle12c." 
CURDIR=$(cd $(dirname $0); pwd)
pushd ${CURDIR}

. ./var.conf

pushd /tmp

### unzip installer ###
find "${INSTALL_ZIP_LOC}" -name *.zip | xargs -n1 unzip -q -d /tmp/


### Oracle12c Install ###
export ORACLE_BASE=/opt/oracle12c/app/oracle
export ORACLE_HOME="${ORACLE_BASE}"/product/12.2.0/dbhome_1
export ORACLE_INST=/opt/oracle12c


cd /etc/yum.repos.d/
wget http://public-yum.oracle.com/public-yum-ol7.repo
cd /etc/pki/rpm-gpg/
wget http://public-yum.oracle.com/RPM-GPG-KEY-oracle-ol7 -O RPM-GPG-KEY-oracle

yum install -y oracle-database-server-12cR2-preinstall
sudo echo "oracle:"${ORACLE_PASS}"" | chpasswd


mkdir -p "${ORACLE_INST}"
chown -R oracle:oinstall "${ORACLE_INST}"

sed -e "s@#ORACLE_INST#@"${ORACLE_INST}"@g" \
    -e "s@#ORACLE_BASE#@"${ORACLE_BASE}"@g" \
    -e "s@#ORACLE_HOME#@"${ORACLE_HOME}"@g" \
 "${CURDIR}"/conf/ora_install.rsp.tmpl > "${ORACLE_INST}"/ora_install.rsp

su - oracle -c "/tmp/database/runInstaller -ignoreSysPrereqs -ignorePrereq -waitforcompletion -silent -responseFile "${ORACLE_INST}"/ora_install.rsp"


su - root -c ""${ORACLE_INST}"/oraInventory/orainstRoot.sh"
su - root -c ""${ORACLE_HOME}"/root.sh"


# Setup Oracle env
cat << EOT > /etc/profile.d/oracle.sh
export ORACLE_BASE=${ORACLE_BASE}
export ORACLE_HOME=${ORACLE_BASE}/product/12.2.0/dbhome_1
export ORACLE_SID=${DB_NAME}
export PATH=\$ORACLE_HOME/bin:\$PATH
export NLS_LANG=Japanese_Japan.AL32UTF8
EOT

. /etc/profile.d/oracle.sh


# Create Database.
sed -e "s@#SYS_PASS#@"${SYS_PASS}"@g" \
    -e "s@#SYSTEM_PASS#@"${SYSTEM_PASS}"@g" \
    -e "s@#ASMSNMP_PASS#@"${ASMSNMP_PASS}"@g" \
    -e "s@#DBSNMP_PASS#@"${DBSNMP_PASS}"@g" \
    -e "s@#DB_NAME#@"${DB_NAME}"@g" \
 "${CURDIR}"/conf/dbca.rsp.tmpl > "${ORACLE_INST}"/dbca.rsp


su - oracle -c ". /etc/profile.d/oracle.sh && dbca -silent -createDatabase -responseFile /opt/oracle12c/dbca.rsp"

sqlplus system/"${SYSTEM_PASS}" << EOF
CREATE USER ${DB_USER} IDENTIFIED BY "${DB_USER_PASS}" DEFAULT TABLESPACE users TEMPORARY TABLESPACE temp;
GRANT UNLIMITED TABLESPACE, DATAPUMP_EXP_FULL_DATABASE, DATAPUMP_IMP_FULL_DATABASE TO ${DB_USER};
exit
EOF


cp "${CURDIR}"/conf/oracle12c /etc/init.d
chmod a+x /etc/init.d/oracle12c
chkconfig --add oracle12c
service oracle12c restart

sed -i -e "s/dbhome_1:N/dbhome_1:Y/" /etc/oratab


### Clean up
rm -rf /tmp/*

