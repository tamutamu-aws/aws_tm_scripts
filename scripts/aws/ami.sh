### ami:wait_creating_image [ami image id]
ami:wait_creating_image() {
  local readonly _ami_image_id="${1}"

  local _retry=0
  local readonly _ssh_max_retry=100
  local _ret=""

  while true
  do
    _ret=$(aws ec2 describe-images --image-ids ${_ami_image_id} \
          | jq -r ".Images[].State")

    [ "${_ret}" = "available" ] && break || echo "Creating AMI Image.."

    _retry=`expr "${_retry}" + 1`
    [ "${_retry}" -eq "${_ssh_max_retry}" ] && (util:r_echo "Timeout. Creating AMI Image!"; exit 1)

    sleep 20
  done

}
