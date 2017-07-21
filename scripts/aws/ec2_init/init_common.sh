#!/bin/bash
set -euo pipefail


declare -r aws_region=$1
export AWS_DEFAULT_REGION="${aws_region}"


### ec2 default ssh user password.
echo "centos" | passwd --stdin centos
 

### Setup hostname.
cat << EOL > /etc/cloud/cloud.cfg.d/update_hostname.cfg
preserve_hostname: true
EOL
 
declare -r instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
declare -r server_name=$(aws ec2 describe-instances \
                  --instance-id ${instance_id} \
                  --query 'Reservations[].Instances[].Tags[?Key==`Name`].Value' \
                  --output text)
 
hostnamectl set-hostname ${server_name}



### CloudWatchLogs Settings.
pushd /tmp

cat << EOT > ./install_awslogs.conf
[general]
state_file = /var/awslogs/state/agent-state

[/var/log/clamd.log]
datetime_format = %Y-%m-%d %H:%M:%S
file = /var/log/clamd.log
buffer_duration = 5000
log_stream_name = {hostname}-{instance_id}
initial_position = start_of_file
log_group_name = /var/log/clamd.log
EOT


curl https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py -O
chmod +x awslogs-agent-setup.py
./awslogs-agent-setup.py -n -r ${aws_region} -c /tmp/install_awslogs.conf
chkconfig awslogs on
sleep 15

popd
