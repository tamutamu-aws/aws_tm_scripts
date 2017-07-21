#!/bin/bash
set -euo pipefail

CURDIR=$(cd $(dirname $0); pwd)
pushd ${CURDIR}


### Execute scripts.
find /tmp/ -name '*.sh' -type f -print | xargs chmod +x


### Execute Install scripts.
./oracle-12c/oracle-12c.sh


### Clean temporary data.
rm -rf /tmp/* /tmp/.[^.] /tmp/.??*

popd
