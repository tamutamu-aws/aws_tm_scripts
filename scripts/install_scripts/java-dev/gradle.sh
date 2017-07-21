#!/bin/bash
set -euo pipefail

echo 'Install gradle2'
CURDIR=$(cd $(dirname $0); pwd)
pushd ${CURDIR}


pushd /tmp

mkdir -p /opt/gradle/

wget --no-check-certificate https://services.gradle.org/distributions/gradle-2.2.1-all.zip
unzip -q gradle-2.2.1-all.zip -d /opt/gradle/

wget --no-check-certificate https://services.gradle.org/distributions/gradle-1.9-all.zip
unzip -q gradle-1.9-all.zip -d /opt/gradle/

alternatives --install /opt/gradle/latest gradle /opt/gradle/gradle-2.2.1 1
alternatives --install /opt/gradle/latest gradle /opt/gradle/gradle-1.9 2

ln -s /opt/gradle/latest/bin/gradle /bin/gradle

alternatives --set gradle /opt/gradle/gradle-2.2.1


cat << 'EOT' > /etc/profile.d/gradle.sh
export GRADLE_HOME=/opt/gradle/latest
EOT

. /etc/profile.d/gradle.sh
popd

set +eu
if [ ! -z "$http_proxy" ]; then
   proxy_host=$(echo $http_proxy | awk '{sub("^http.*://","");sub(":[0-9]*","");print $0}')
   proxy_port=$(echo $http_proxy | awk '{sub("^http.*:","");print $0}')

   mkdir -p /root/.gradle/

   cat << EOT >> /root/.gradle/gradle.properties
systemProp.http.proxyHost=${proxy_host}
systemProp.http.proxyPort=${proxy_port}
systemProp.https.proxyHost=${proxy_host}
systemProp.https.proxyPort=${proxy_port}
EOT
fi
set -eu


## Copy change gradle version script
mkdir -p /opt/scripts/java
cp $CURDIR/conf/ch_gradle.sh /opt/scripts/java/
chmod a+x /opt/scripts/java/ch_gradle.sh

popd
