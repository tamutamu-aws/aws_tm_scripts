ssh:remote_copy(){
 
  local readonly _connect_ip="${1}"
  local readonly _ssh_user="${2}"
  local readonly _ssh_pass="${3}"
  local readonly _local_dir="${4}"
  local readonly _remote_dir="${5}"
 
  ssh:wait_connect "${_connect_ip}" "${_ssh_user}" "${_ssh_pass}"

  sshpass -p ${_ssh_pass} \
        ssh -t -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${_ssh_user}@${_connect_ip} \
          "sudo mkdir -p ${_remote_dir} && sudo chown ${_ssh_user}:${_ssh_user} ${_remote_dir}"

  sshpass -p ${_ssh_pass} \
    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r ${_local_dir} ${_ssh_user}@${_connect_ip}:${_remote_dir}
 
}



ssh:remote_exec_shell(){
  local readonly _connect_ip="${1}"
  local readonly _ssh_user="${2}"
  local readonly _ssh_pass="${3}"
  local readonly _shell_cmd="${4}"

  ssh:wait_connect "${_connect_ip}" "${_ssh_user}" "${_ssh_pass}"

  sshpass -p ${_ssh_pass} \
        ssh -t -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${_ssh_user}@${_connect_ip} \
        "${_shell_cmd}"

}



ssh:wait_connect(){

  local readonly _connect_ip="${1}"
  local readonly _ssh_user="${2}"
  local readonly _ssh_pass="${3}"

  local _retry=0
  local readonly _ssh_max_retry=15
  local _ret=""

  while true
  do
    sshpass -p ${_ssh_pass} \
      ssh -n -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 \
       ${_ssh_user}@${_connect_ip} echo ssh > /dev/null

    _ret="$?"
    [ "${_ret}" = "0" ] && break || echo "ssh: timeout, reconnect.. "

    _retry=`expr "${_retry}" + 1`
    [ "${_retry}" -eq "${_ssh_max_retry}" ] && (util:r_echo "ssh error: retry max."; exit 1)

    sleep 10
  done
}
