#!/bin/bash
set -euo pipefail
 
. ../../config/general.sh
. ../../scripts/utils/util.sh
. ../../scripts/utils/ssh_pass.sh
. ../../scripts/aws/ami.sh
. ../../scripts/aws/ec2.sh
. ../../scripts/aws/vpc.sh
 
. var.conf
 
 
### Get VPC Info.
declare -r vpc_id=$(vpc:get_vpc_id "${VPC_CIDR}")
declare -r subnet_id=$(vpc:get_subnet_id "${AMI_BUILD_SUBNET_CIDR}")


### Security Group for SSH, for temporary.
declare -r sg_id=$(ec2:create_temporary_sg ${vpc_id} ${MARBLE_PRIVATE_IP}/32)


### Startup ec2 instance.
sed -e "s/#SSH_PASSWORD#/${SOURCE_AMI_USER}/" ./user-data.sh.tmpl > user-data.sh

readonly instance_id=$(ec2:create_instance \
                                  "${AMI_NAME}"_AMI_BUILD \
                                  "${SOURCE_AMI_ID}" \
                                  "${AWS_BASTION_KEY_PAIR_NAME}" \
                                  "${sg_id}" \
                                  "${EC2_TYPE}" \
                                  "20" \
                                  "${subnet_id}" \
                                  "user-data.sh")


### Get Private IP.
readonly private_ip=$(ec2:get_private_ip "${instance_id}")
 

### Provisioning.
set +e
remote_copy(){
  ssh:remote_copy \
    ${private_ip} \
    ${SOURCE_AMI_USER} \
    ${SOURCE_AMI_USER} \
    $1 \
    /tmp/provision/
}
remote_copy '../../scripts/install_scripts/clamav/'
remote_copy './provision.sh'

ssh:remote_exec_shell \
    ${private_ip} \
    ${SOURCE_AMI_USER} \
    ${SOURCE_AMI_USER} \
    "sudo chmod a+x /tmp/provision/provision.sh && \
     sudo -E /tmp/provision/provision.sh ${SOURCE_AMI_USER}" 
set -e
 
 
### Create AMI.
readonly ami_id=$(aws ec2 create-image --instance-id "${instance_id}" --name "init_${AMI_NAME}_$(date "+%Y%m%d_%H%M%S")" --reboot \
                  | jq -r '.ImageId')
aws ec2 create-tags --resources ${ami_id} --tags Key=Description,Value="踏み台サーバのイメージ。"
ami:wait_creating_image ${ami_id} 

 
### Celan up
aws ec2 terminate-instances --instance-id "${instance_id}"
aws ec2 wait instance-terminated --instance-id="${instance_id}"
aws ec2 delete-security-group --group-id ${sg_id} 
