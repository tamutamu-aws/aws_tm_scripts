#!/bin/bash
set -euo pipefail

. ../../config/general.sh
. ../../scripts/utils/util.sh
. ../../scripts/aws/ami.sh
. ../../scripts/aws/ec2.sh
. ../../scripts/aws/vpc.sh

declare -r INSTANCE_ID=${1}


### Get ec2 Name tag.
readonly ec2_name=$(aws ec2 describe-tags --filters "Name=resource-id,Values=${INSTANCE_ID}" "Name=key,Values=Name" \
                    | jq -r '.Tags[].Value')

# Return EC2 Name.
echo "EC2 Name:${ec2_name}"
