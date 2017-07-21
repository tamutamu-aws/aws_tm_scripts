#!/bin/bash
set -euo pipefail
 
. ../../config/general.sh
. ../../scripts/utils/util.sh
. ../../scripts/utils/ssh_pass.sh
. ../../scripts/aws/ami.sh
. ../../scripts/aws/ec2.sh
. ../../scripts/aws/vpc.sh
 
. var.conf


declare instance_id=""

### Source Common Err Trap.
. ../../scripts/utils/common_final_trap.sh 

 
### create EC2 instance
set +e
# Set ssh password for user 'centos'.
sed -e "s/#SSH_PASSWORD#/${SOURCE_AMI_USER}/" ./user-data.sh.tmpl > user-data.sh
instance_id=$(ec2:create_instance4nw \
                                  "${EC2_NAME}" \
                                  "${AMI_ID}" \
                                  "${AWS_COMMON_KEY_PAIR_NAME}" \
                                  "${NETWORK_IF_ID}" \
                                  "${INSTANCE_TYPE}" \
                                  "${VOL_SIZE}" \
                                  "user-data.sh")


aws ec2 wait instance-running --instance-id="${instance_id}"
aws ec2 modify-instance-attribute --instance-id="${instance_id}" --disable-api-termination

# Put tags.
aws ec2 create-tags --resources "${instance_id}" --tags Key=Group,Value="${GROUP}" > /dev/null
aws ec2 create-tags --resources "${instance_id}" --tags Key=Description,Value="${DESC}" > /dev/null


### Attach IAM Instance Profile.
aws ec2 associate-iam-instance-profile --instance-id ${instance_id} --iam-instance-profile Name=${COMMON_IAM_INST_PROFILE} > /dev/null
 

# Associate EIP
readonly eip_id=$(ec2:get_eip_id "${BISCO_EIP}")
aws ec2 associate-address --instance-id "${instance_id}" --allocation-id "${eip_id}" > /dev/null

# Get Public IP.
readonly public_ip=$(ec2:get_public_ip ${instance_id})

set -e
 

### Init Provision
remote_copy(){
  ssh:remote_copy \
    ${public_ip} \
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
      ${public_ip} \
      ${SOURCE_AMI_USER} \
      ${SOURCE_AMI_USER} \
      "sudo chmod a+x /tmp/provision/ebs_grows.sh && \
        sudo /tmp/provision/ebs_grows.sh"
set -e
 

echo "EC2 "${EC2_NAME}" instance start."
