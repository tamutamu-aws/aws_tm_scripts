#!/bin/bash
set -euo pipefail
 
. ../../config/general.sh
. ../../scripts/utils/util.sh

. var.conf

readonly ret=$(aws ec2 describe-hosts | jq -c '.Hosts | length')

if [ "${ret}" = "0" ]; then
  echo ""
else
  echo $(aws ec2 describe-hosts | jq -r '.Hosts[].HostId')
fi
