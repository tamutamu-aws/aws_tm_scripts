### Provisioning.
set +e
remote_copy '../../scripts/install_scripts/oracle-12c/'
remote_copy './provision.sh'

ssh:remote_exec_shell \
    ${private_ip} \
    ${SOURCE_AMI_USER} \
    ${SOURCE_AMI_USER} \
    "sudo chmod a+x /tmp/provision/provision.sh && \
      sudo -E /tmp/provision/provision.sh"


### EC2 default setup
remote_copy '../../scripts/aws/ec2_init/init_common.sh'
 
ssh:remote_exec_shell \
      ${private_ip} \
      ${SOURCE_AMI_USER} \
      ${SOURCE_AMI_USER} \
      "sudo chmod a+x /tmp/provision/init_common.sh && \
        sudo /tmp/provision/init_common.sh ${AWS_DEFAULT_REGION}"
set -e
