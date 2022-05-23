#!/bin/bash
 
#---------------------------------------------------------------
#  Getting input parameters
#---------------------------------------------------------------
while getopts s:n:g:t: flag
do
    case "${flag}" in
        s) server=${OPTARG};;
        n) username=${OPTARG};;
	g) group=${OPTARG};;
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

if [ -z "$group" ]; then
   group="$username"  
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
# Creating a user name that people can't think of
#---------------------------------------------------------------
postfix=$(echo $RANDOM | md5sum | head -c 20; echo;)
username="${username}_${postfix}"


#---------------------------------------------------------------
# Check whether temporary user if user exist
#---------------------------------------------------------------
echo "Checking whether a new temporary user exists already or not.."
vault read db/roles/acc_$username &> /dev/null
if [ $? == "0" ]; then
	echo "  The corresponding username is no longer available. - username: $username"
	exit 1
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

dbuser=$(vault read db/creds/acc_$username -format=json | jq .data.username |  tr -d '"') 
mastepass=$(vault write ssh-client-onetime-pass/creds/otp_key_role ip=$server -format=json | jq .data.key |  tr -d '"') 
sshpass -p $mastepass ssh ubuntu@$server "bash -s" -- < ./addUserToRemoteServer.sh -n $username -a $dbuser -g $group &> /dev/null

if [ ! $? == "0" ]; then
    echo "  failed to add a new temporary user to target server - server: $server, username: $username"
    exit 1
else 
    echo "  success to add a new temporary user to target server - server: $server, username: $username"
fi

#---------------------------------------------------------------
# Set SSH Role  
#---------------------------------------------------------------
echo "Creating a otp role for temporary user.."

vault write ssh-client-onetime-pass/roles/otp_role_$username \
     key_type=otp \
     default_user=$username \
     allowed_user=$username \
     key_bits=2048 \
     cidr_list=0.0.0.0/0  &> /dev/null

if [ ! $? == "0" ]; then
    echo "  failed to create a otp role for temporary user - otp_role_$username"
    exit 1
else 
    echo "  success to create a otp role for temporary user - otp_role_$username"
fi

echo ""
echo ""	 
echo "Try : vault write ssh-client-onetime-pass/creds/otp_role_$username ip=$server"
echo "Try : ssh $username@$server" 
echo "Vaildation : $validtime"
