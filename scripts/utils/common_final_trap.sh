 common_final_trap(){                                                                                                                                                       
   if [ -n "${instance_id}"  ]; then 
     util:m_echo "EC2 InstanceId : ${instance_id}"
   else
     util:m_echo "EC2インスタンスは作成されていません。"
   fi
 }
 trap 'common_final_trap' EXIT
