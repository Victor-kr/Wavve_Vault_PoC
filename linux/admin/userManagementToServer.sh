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
#  Vault login
#---------------------------------------------------------------
export VAULT_ADDR=${VAULT_ADDR:-http://172.31.44.220:8200}
export VAULT_TOKEN=${VAULT_TOKEN:-hvs.zpu3IwU6OyNBg7iDN8DbWb3K}
vault login $VAULT_TOKEN

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
tempuser=$(vault read db/creds/acc_$username -format=json | jq .data.username |  tr -d '"') 
mastepass=$(vault write ssh-client-onetime-pass/creds/otp_key_role ip=$server -format=json | jq .data.key |  tr -d '"') 
sshpass -p $mastepass ssh ubuntu@$server "bash -s" -- < ./addUserToRemoteServer.sh -n $tempuser

#---------------------------------------------------------------
# Set SSH Role  
#---------------------------------------------------------------
vault write ssh-client-onetime-pass/roles/otp_role_$tempuser \
     key_type=otp \
     default_user=$tempuser \
     allowed_user=$tempuser \
     key_bits=2048 \
     cidr_list=0.0.0.0/0
	 
	 
echo "Try : vault write ssh-client-onetime-pass/creds/otp_role_$tempuser ip=$server"
echo "Try : ssh $tempuser@$server" 
echo "Vaildation : $validtime" 
 
