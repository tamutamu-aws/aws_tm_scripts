#!/bin/bash
set -euo pipefail

. ../../config/general.sh
. ../../scripts/utils/util.sh
. ../../scripts/aws/ami.sh
. ../../scripts/aws/ec2.sh
. ../../scripts/aws/vpc.sh

declare -r INSTANCE_ID=${1}
declare -r EC2_NAME=${2}
declare -r DESC="${3}"
declare -r GROUP="${4}"


### Create AMI.
readonly ami_id=$(aws ec2 create-image --instance-id "${INSTANCE_ID}" --name "${EC2_NAME}_backup_$(date "+%Y%m%d_%H%M%S")" --reboot \
                  | jq -r '.ImageId')

aws ec2 create-tags --resources ${ami_id} --tags Key=Description,Value="${DESC}" Key=Group,Value="${GROUP}"

ami:wait_creating_image ${ami_id}

# Output Create AMI Image info.
aws ec2 describe-images --image-ids ${ami_id}

