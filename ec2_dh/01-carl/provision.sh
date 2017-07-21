#!/bin/bash
set -euo pipefail

CURDIR=$(cd $(dirname $0); pwd)
pushd ${CURDIR}


### Execute scripts.
find /tmp/ -name '*.sh' -type f -print | xargs chmod +x


### Execute Install scripts.
./apache/apache.sh
./tomcat-8/tomcat-8.sh


### Clean temporary data.
rm -rf /tmp/* /tmp/.[^.] /tmp/.??*

popd
