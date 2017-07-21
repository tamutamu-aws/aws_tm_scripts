#!/bin/bash
set -euo pipefail

echo 'Install maven3'
CURDIR=$(cd $(dirname $0); pwd)
pushd ${CURDIR}


pushd /tmp
wget https://archive.apache.org/dist/maven/maven-3/3.2.5/binaries/apache-maven-3.2.5-bin.zip 
unzip -q apache-maven-3.2.5-bin.zip
mv apache-maven-3.2.5 /opt/maven
ln -s /opt/maven/bin/mvn /usr/bin/mvn

cat << 'EOT' > /etc/profile.d/maven3.sh 
export MAVEN_HOME=/opt/maven
EOT
 
. /etc/profile.d/maven3.sh 
popd

set +eu
if [ ! -z "$http_proxy" ]; then
   proxy_host=$(echo $http_proxy | awk '{sub("^http.*://","");sub(":[0-9]*","");print $0}')
   proxy_port=$(echo $http_proxy | awk '{sub("^http.*:","");print $0}')

   mkdir -p /root/.m2/
   
   cat ./conf/maven/settings.xml | \
     gawk -f ./conf/maven/add_proxy.awk -v PROXY_HOST="${proxy_host}" -v PROXY_PORT="${proxy_port}" \
     > /root/.m2/settings.xml

   mv /root/.m2/settings.xml.tmp /root/.m2/settings.xml
fi
set -eu


popd
