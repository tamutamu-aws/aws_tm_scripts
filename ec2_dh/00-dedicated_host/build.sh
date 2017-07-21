#!/bin/bash
set -euo pipefail
 
. ../../config/general.sh
. ../../scripts/utils/util.sh
 
. var.conf
 
 
### Create EC2 Dedicated Host.
readonly dh_host_id=$(aws ec2 allocate-hosts --instance-type "${DH_INSTANCE_TYPE}" \
                       --availability-zone "${DH_AZ}" \
                       --auto-placement "off" \
                       --quantity 1 \
                       --region ${DH_REGION} \
                     | jq -r '.HostIds[]')


### Return Dedicated Host Id.
echo "Allocate Dedicated Host Id:${dh_host_id} "
