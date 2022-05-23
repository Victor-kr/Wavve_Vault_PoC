#!/bin/bash

#---------------------------------------------------------------
#  Getting input parameters
#---------------------------------------------------------------
while getopts n:d:g:s: flag
do
    case "${flag}" in
        s) server=${OPTARG};;
        n) username=${OPTARG};;
		t) validtime=${OPTARG};;
    esac
done

#---------------------------------------------------------------
#  Checking input parameters
#---------------------------------------------------------------
if [ -z "$server" ]; then
    echo '[Error] Please put a remote server name or ipaddress.'
    exit 1   
fi

if [ -z "$username" ]; then
    echo '[Error] Please put a username prefix.'
    exit 1   
fi

if [ -z "$validtime" ]; then
   validtime="5m"  
fi

#---------------------------------------------------------------
#  Vault login > 파라미터 빼야함
#---------------------------------------------------------------
export VAULT_ADDR="http://172.31.37.26:8200"
vault login hvs.zpu3IwU6OyNBg7iDN8DbWb3K



#---------------------------------------------------------------
#  Set Account Role
#---------------------------------------------------------------
vault write db/roles/acc_$username \
    db_name=mysqldb \
    creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';" \
    default_ttl="${validtime}" \
    max_ttl="${validtime}"

#---------------------------------------------------------------
# Add a temporary user to target server
#---------------------------------------------------------------
temp_user=$(vault read db/creds/acc_$username -format=json | jq .data.username |  tr -d '"')
master_user_onetime_pass=$(vault write ssh-client-onetime-pass/creds/otp_$username_role ip=$server -format=json | jq .data.key |  tr -d '"') 
sshpass -p $master_user_onetime_pass ssh ubuntu@$server "bash -s" -- < ./addUserToRemoteServer.sh -n $temp_user
 

#---------------------------------------------------------------
# Set SSH Role  
#---------------------------------------------------------------
vault write ssh-client-onetime-pass/roles/otp_role_$temp_user \
     key_type=otp \
     default_user=$temp_user \
     allowed_user=$temp_user \
     key_bits=2048 \
     cidr_list=0.0.0.0/0
	 
	 
echo "Try : vault write ssh-client-onetime-pass/creds/otp_role_$temp_user ip=$server"
echo "Try : ssh $temp_user@$server" 
echo "Vaildation : $validtime" 
 
