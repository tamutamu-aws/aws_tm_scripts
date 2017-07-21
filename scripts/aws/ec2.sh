### ec2:create_instance [ec2 name] [ami id] [key name] [security group id] [ec2 type] [volume size] [subnet id] [user-data file]
ec2:create_instance() {
  local readonly _ec2_name="${1}"
  local readonly _ami_id="${2}"
  local readonly _key_name="${3}"
  local readonly _sg_name="${4}"
  local readonly _ec2_type="${5}"
  local readonly _volume_size="${6}"
  local readonly _subnet_id="${7}"
  local readonly _user_data_file="${8}"

  local _create_cmd="aws ec2 run-instances \
                     --image-id ${_ami_id} \
                     --key-name ${_key_name} \
                     --subnet-id ${_subnet_id} \
                     --security-group-ids ${_sg_name} \
                     --block-device-mappings '[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":${_volume_size},\"DeleteOnTermination\":false,\"VolumeType\":\"gp2\"}}]' \
                     --instance-type ${_ec2_type}"


  # if User-data exists.
  if [ -n ${_user_data_file} ]; then
    _create_cmd="${_create_cmd} --user-data file://${_user_data_file}"
  fi

  # Create EC2.
  local _ret=$(eval ${_create_cmd})
  
  local readonly _instance_id=$(echo "${_ret}" | jq -r ".Instances[].InstanceId")
  aws ec2 wait instance-running --instance-id="${_instance_id}"

  aws ec2 create-tags --resources "${_instance_id}" --tags Key=Name,Value="${_ec2_name}" > /dev/null
 
  echo "${_instance_id}"
}


### ec2:create_instance4nw [ec2 name] [ami id] [key name] [network interface id] [ec2 type] [volume size] [user-data file]
ec2:create_instance4nw() {
  local readonly _ec2_name="${1}"
  local readonly _ami_id="${2}"
  local readonly _key_name="${3}"
  local readonly _nw_id="${4}"
  local readonly _ec2_type="${5}"
  local readonly _volume_size="${6}"
  local readonly _user_data_file="${7}"

  local _create_cmd="aws ec2 run-instances \
                 --image-id ${_ami_id} \
                 --key-name ${_key_name} \
                 --network-interface '[{\"DeviceIndex\":0,\"NetworkInterfaceId\":\"${_nw_id}\"}]'  \
                 --block-device-mappings '[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":${_volume_size},\"DeleteOnTermination\":false,\"VolumeType\":\"gp2\"}}]' \
                 --instance-type ${_ec2_type}"


  # if User-data exists.
  if [ -n ${_user_data_file} ]; then
    _create_cmd="${_create_cmd} --user-data file://${_user_data_file}"
  fi

  # Create EC2.
  local _ret=$(eval ${_create_cmd})

  local readonly _instance_id=$(echo "${_ret}" | jq -r ".Instances[].InstanceId")
  aws ec2 wait instance-running --instance-id="${_instance_id}"

  aws ec2 create-tags --resources "${_instance_id}" --tags Key=Name,Value="${_ec2_name}" > /dev/null
 
  echo "${_instance_id}"
}


### ec2:create_instance4nwWithPlacement [ec2 name] [ami id] [key name] [network interface id] [ec2 type] [volume size] [placement args]
ec2:create_instance4nwWithPlacement() {
  local readonly _ec2_name="${1}"
  local readonly _ami_id="${2}"
  local readonly _key_name="${3}"
  local readonly _nw_id="${4}"
  local readonly _ec2_type="${5}"
  local readonly _volume_size="${6}"
  local readonly _placement_args="${7}"

  local _create_cmd="aws ec2 run-instances \
                 --image-id ${_ami_id} \
                 --key-name ${_key_name} \
                 --network-interface '[{\"DeviceIndex\":0,\"NetworkInterfaceId\":\"${_nw_id}\"}]'  \
                 --block-device-mappings '[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":${_volume_size},\"DeleteOnTermination\":false,\"VolumeType\":\"gp2\"}}]' \
                 --placement ${_placement_args} \
                 --instance-type ${_ec2_type}"

  # Create EC2.
  local _ret=$(eval ${_create_cmd})

  local readonly _instance_id=$(echo "${_ret}" | jq -r ".Instances[].InstanceId")
  aws ec2 wait instance-running --instance-id="${_instance_id}"

  aws ec2 create-tags --resources "${_instance_id}" --tags Key=Name,Value="${_ec2_name}" > /dev/null
 
  echo "${_instance_id}"
}


### ec2:get_eip_id [eip ip]
ec2:get_eip_id() {
  local readonly _eip_ip="${1}"

  echo $(aws ec2 describe-addresses --filters "Name=public-ip,Values=${_eip_ip}" \
        | jq -r '.Addresses[].AllocationId')
}



### ec2:get_public_ip [instance id]
ec2:get_public_ip() {
  local readonly _instance_id="${1}"

  echo $(aws ec2 describe-instances --instance-id ${_instance_id} \
         | jq -r '.Reservations[].Instances[] | .PublicIpAddress')
}


### ec2:get_private_ip [instance id]
ec2:get_private_ip() {
  local readonly _instance_id="${1}"

  echo $(aws ec2 describe-instances --instance-id ${_instance_id} \
         | jq -r '.Reservations[].Instances[] | .PrivateIpAddress')
}


### ec2:check_exist_sg [security group name]
ec2:check_exist_sg() {
  local _ret="$(aws ec2 describe-security-groups --filters Name=group-name,Values="${1}" \
              | jq -r '.SecurityGroups[].GroupId')"

  if [[ -n "${_ret}" ]]; then
    util:r_echo "Error!!."
    util:r_echo "Security Group "${1}" already exists."
    echo
    util:m_echo "Delete Security Group "${1}"."
    exit 1
  fi
}


### ec2:create_temporary_sg [vpc id] [ssh only access cider]
ec2:create_temporary_sg() {
  local readonly _vpc_id="${1}"
  local readonly _ssh_from_only_cidr="${2}"

  local readonly _sg_id=$(aws ec2 create-security-group --group-name "AMI_BUILD_SHAccess_$(date "+%Y%m%d_%H%M%S")" \
                                  --vpc-id "${_vpc_id}" --description "AMI_BUILD SSH access for AMI build." \
                          | jq -r ".GroupId")
  
  aws ec2 create-tags --resources "${_sg_id}" --tags Key=Name,Value="AMI_BUILD" > /dev/null

  aws ec2 authorize-security-group-ingress --group-id "${_sg_id}" --protocol tcp --port 22 --cidr ${_ssh_from_only_cidr} > /dev/null

  echo ${_sg_id}
}



### ec2:get_sgid4nwif [ network interface id]
ec2:get_sgid4nwif() {
  local readonly _nwif_id="${1}"

  local _sg_id=$(aws ec2 describe-network-interfaces \
                  --filters "Name=network-interface-id, Values=${_nwif_id}" \
                  | jq -r '.NetworkInterfaces[].Groups[].GroupId')

  echo ${_sg_id}
}
