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
# Set ssh password for user 'centos'.
sed -e "s/#SSH_PASSWORD#/${SOURCE_AMI_USER}/" ./user-data.sh.tmpl > user-data.sh

# Run EC2.
readonly instance_id=$(ec2:create_instance \
                                  "${AMI_NAME}"_AMI_BUILD \
                                  "${SOURCE_AMI_ID}" \
                                  "${AWS_COMMON_KEY_PAIR_NAME}" \
                                  "${sg_id}" \
                                  "${EC2_TYPE}" \
                                  "20" \
                                  "${subnet_id}" \
                                  "user-data.sh")


### Attach IAM Instance Profile.
aws ec2 associate-iam-instance-profile --instance-id ${instance_id} --iam-instance-profile Name=${COMMON_IAM_INST_PROFILE} > /dev/null


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

# copy install script to provisioning server.
remote_copy '../../scripts/install_scripts/common-dev/'
remote_copy '../../scripts/install_scripts/aws/'
remote_copy '../../scripts/install_scripts/clamav/'
remote_copy '../../scripts/install_scripts/java-dev/'
remote_copy './provision.sh'

# execute scripts.
ssh:remote_exec_shell \
    ${private_ip} \
    ${SOURCE_AMI_USER} \
    ${SOURCE_AMI_USER} \
    "sudo chmod a+x /tmp/provision/provision.sh && \
     sudo -E /tmp/provision/provision.sh ${S3_BUCKET_NAME}"
set -e
 
 
### Create AMI.
readonly ami_id=$(aws ec2 create-image --instance-id "${instance_id}" --name "init_${AMI_NAME}_$(date "+%Y%m%d_%H%M%S")" --reboot \
                  | jq -r '.ImageId')

aws ec2 create-tags --resources ${ami_id} --tags \
  Key=Group,Value="common" \
  Key=Description,Value="jdk、maven、gradle等開発ツールがインストールされたベースAMI."

ami:wait_creating_image ${ami_id} 

 
### Clean up.
aws ec2 terminate-instances --instance-id "${instance_id}" > /dev/null
aws ec2 wait instance-terminated --instance-id="${instance_id}"
aws ec2 delete-security-group --group-id ${sg_id}
