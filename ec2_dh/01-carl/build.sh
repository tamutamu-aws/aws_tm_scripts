#!/bin/bash
set -euo pipefail
 
. ../../config/general.sh
. ../../scripts/utils/util.sh
. ../../scripts/utils/ssh_pass.sh
. ../../scripts/aws/ami.sh
. ../../scripts/aws/ec2.sh
. ../../scripts/aws/vpc.sh
 
. var.conf
. ../00-dedicated_host/var.conf


### Dedicated Host ID
declare -r DH_HOST_ID=${1}

declare instance_id=""

### Source Common Err Trap.
. ../../scripts/utils/common_final_trap.sh 

 
### create EC2 instance
set +e
instance_id=$(ec2:create_instance4nwWithPlacement \
                                  "${EC2_NAME}" \
                                  "${AMI_ID}" \
                                  "${AWS_COMMON_KEY_PAIR_NAME}" \
                                  "${NETWORK_IF_ID}" \
                                  "${INSTANCE_TYPE}" \
                                  "${VOL_SIZE}" \
                                  "AvailabilityZone=${DH_AZ},HostId=${DH_HOST_ID},Tenancy=host")


aws ec2 wait instance-running --instance-id="${instance_id}"
aws ec2 modify-instance-attribute --instance-id="${instance_id}" --disable-api-termination

# Put tags.
aws ec2 create-tags --resources "${instance_id}" --tags Key=Group,Value="${GROUP}" > /dev/null
aws ec2 create-tags --resources "${instance_id}" --tags Key=Description,Value="${DESC}" > /dev/null


### Attach IAM Instance Profile.
aws ec2 associate-iam-instance-profile --instance-id ${instance_id} --iam-instance-profile Name=${COMMON_IAM_INST_PROFILE} > /dev/null
 

# Associate EIP
readonly public_ip=${CARL_EIP}
readonly eip_id=$(ec2:get_eip_id "${public_ip}")
aws ec2 associate-address --instance-id "${instance_id}" --allocation-id "${eip_id}" > /dev/null


# Get Private IP.
readonly private_ip=$(ec2:get_private_ip ${instance_id})
set -e
 

### Init Provision
remote_copy(){
  ssh:remote_copy \
    ${private_ip} \
    ${SOURCE_AMI_USER} \
    ${SOURCE_AMI_USER} \
    $1 \
    /tmp/provision/
}

if ${INIT_PROVISION}; then
  . ./init.sh
fi
 

### EBS Grows
set +e
remote_copy '../../scripts/aws/ec2_init/ebs_grows.sh'

ssh:remote_exec_shell \
      ${private_ip} \
      ${SOURCE_AMI_USER} \
      ${SOURCE_AMI_USER} \
      "sudo chmod a+x /tmp/provision/ebs_grows.sh && \
        sudo /tmp/provision/ebs_grows.sh"
set -e
 

echo "EC2 "${EC2_NAME}" instance start."
