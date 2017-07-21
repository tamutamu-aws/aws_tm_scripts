### Basic
declare -xr AWS_DEFAULT_REGION=ap-northeast-1
declare -xr AWS_BASTION_KEY_PAIR_NAME=
declare -xr AWS_COMMON_KEY_PAIR_NAME=


### AMI Build Settings.
# CentOS Linux 7 x86_64
declare -xr SOURCE_AMI_USER=centos
declare -xr SOURCE_AMI_ID=ami-29d1e34e


### IAM Instace profile
declare -xr COMMON_IAM_INST_PROFILE=
declare -xr JOB_IAM_INST_PROFILE=


### BASE AMI ID
declare -xr BASE_AMI_ID=


### EIP etc..
declare -xr BASTION_EIP=
declare -xr CARL_EIP=
declare -xr MARBLE_EIP=
declare -xr OZAC_EIP=
declare -xr BISCO_EIP=


### VPC Settings.
declare -xr DEFAULT_VPC_CIDR=172.31.0.0/16
declare -xr DEFAULT_PUBLIC_SUBNET_CIDR=10.0.0.0/24

declare -xr VPC_CIDR=10.0.0.0/16
declare -xr PUBLIC_SUBNET_CIDR_1=10.0.0.0/24
declare -xr PUBLIC_SUBNET_CIDR_2=10.0.2.0/24
declare -xr PRIVATE_SUBNET_CIDR_1=10.0.1.0/24
declare -xr PRIVATE_SUBNET_CIDR_2=10.0.3.0/24
declare -xr AMI_BUILD_SUBNET_CIDR=10.0.0.0/24


### Security Settings.
declare -xr ONLY_ACCESS_FROM=


### S3 Bucket Name
declare -xr S3_BUCKET_NAME=


### PRIVATE IP
declare -xr BASTION_PRIVATE_IP=
declare -xr CARL_PRIVATE_IP=
declare -xr MARBLE_PRIVATE_IP=


### For Manage Job
declare -xr FROM_MARBLE_SSH_SGID=

