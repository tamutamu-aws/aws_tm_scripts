#!/bin/bash
set -euo pipefail
 
echo "Install AWS Utility."
CURDIR=$(cd $(dirname $0); pwd)
pushd ${CURDIR}
 
 
### awscli
yum -y install python-pip
pip install awscli
 
 
### s3 mount utility
yum -y install golang fuse
wget https://github.com/kahing/goofys/releases/download/v0.0.10/goofys -P /usr/bin/
chmod a+x /usr/bin/goofys


popd
