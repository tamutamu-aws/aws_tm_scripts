#!/bin/bash
set -euo pipefail

. ../../config/general.sh
. ../../scripts/utils/util.sh
. ../../scripts/aws/ami.sh
. ../../scripts/aws/ec2.sh
. ../../scripts/aws/vpc.sh

declare -r INSTANCE_ID=${1}


### Get ec2 Description tag.
readonly ec2_desc=$(aws ec2 describe-tags --filters "Name=resource-id,Values=${INSTANCE_ID}" "Name=key,Values=Description" \
                    | jq -r '.Tags[].Value')

# Return EC2 Description.
echo "EC2 Description:${ec2_desc}"
