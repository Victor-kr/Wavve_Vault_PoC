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

echo "Checking vault status..."
vault status &> /dev/null
if [ ! $? == "0" ]; then
    echo "  vault status : error"
    exit 1
else 
    echo "  vault status : ok"
fi

echo "Checking login to vault.."
vault login -method=userpass \
    username=otpadmin \
    password=password &> /dev/null
	
if [ ! $? == "0" ]; then
    echo "  login failed - username: otpadmin"
    exit 1
else 
    echo "  login success - username: otpadmin"
fi

#---------------------------------------------------------------
#  Set Account Role
#---------------------------------------------------------------
echo "Creating a new account role.."

vault write db/roles/acc_$username \
    db_name=mysqldb \
    creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';" \
    default_ttl="${validtime}" \
    max_ttl="${validtime}" &> /dev/null

if [ ! $? == "0" ]; then
    echo "  failed to create a new account role - rolename : db/roles/acc_$username"
    exit 1
else 
    echo "  success to create a new account role - rolename : db/roles/acc_$username"
fi

#---------------------------------------------------------------
# Add a temporary user to target server
#---------------------------------------------------------------
echo "Creating a temporary user to target server.."

tempuser=$(vault read db/creds/acc_$username -format=json | jq .data.username |  tr -d '"') 
mastepass=$(vault write ssh-client-onetime-pass/creds/otp_key_role ip=$server -format=json | jq .data.key |  tr -d '"') 
sshpass -p $mastepass ssh ubuntu@$server "bash -s" -- < ./addUserToRemoteServer.sh -n $tempuser  &> /dev/null

if [ ! $? == "0" ]; then
    echo "  failed to add a new temporary user to target server - server: $server, username: $tempuser"
    exit 1
else 
    echo "  success to add a new temporary user to target server - server: $server, username: $tempuser"
fi

#---------------------------------------------------------------
# Set SSH Role  
#---------------------------------------------------------------
echo "Creating a otp role for temporary user.."

vault write ssh-client-onetime-pass/roles/otp_role_$tempuser \
     key_type=otp \
     default_user=$tempuser \
     allowed_user=$tempuser \
     key_bits=2048 \
     cidr_list=0.0.0.0/0  &> /dev/null

if [ ! $? == "0" ]; then
    echo "  failed to create a otp role for temporary user - otp_role_$tempuser"
    exit 1
else 
    echo "  success to create a otp role for temporary user - otp_role_$tempuser"
fi

echo ""
echo ""	 
echo "Try : vault write ssh-client-onetime-pass/creds/otp_role_$tempuser ip=$server"
echo "Try : ssh $tempuser@$server" 
echo "Vaildation : $validtime"
