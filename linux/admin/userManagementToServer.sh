#!/bin/bash

#---------------------------------------------------------------
#  Functions
#---------------------------------------------------------------
function vault-provision() {
  path=$1
  shift
  payload="$*"

  curl \
    --request POST \
    --header "X-Vault-Token: ${VAULT_TOKEN}" \
    --data @"${payload}" \
    "${VAULT_ADDR}/v1/${path}" 
}

function vault-get-role-id() {
  rolename="$1"
  shift
  res=$(curl \
      --silent \
      --request GET \
      --header 'Accept: application/json'  \
      --header "X-Vault-Token: ${VAULT_TOKEN}" \
      "${VAULT_ADDR}/v1/auth/approle/role/${rolename}/role-id" | jq .data.role_id)
  echo $res
}

function vault-get-role-secret-id() {
  rolename="$1"
  shift
  res=$(curl \
      --silent \
      --request POST \
      --header 'Accept: application/json'  \
      --header "X-Vault-Token: ${VAULT_TOKEN}" \
      "${VAULT_ADDR}/v1/auth/approle/role/${rolename}/secret-id" | jq .data.secret_id)
  echo $res
}

function vault-get-ssh-cred() {
  path=$1
  shift
  ip="$*"

  postfix=$(echo $RANDOM | md5sum | head -c 20; echo;)
  payload="/tmp/ssh-cred-${postfix}.json"

  jq -n \
    --arg ip "$ip" \
    '{"ip": $ARGS.named["ip"]}' > "${payload}"

  res=$(curl \
    --silent \
    --request POST \
    --header "X-Vault-Token: ${VAULT_TOKEN}" \
    --data @"${payload}" \
    "${VAULT_ADDR}/v1/${path}"  | jq .data.key |  tr -d '"')

   sudo rm -rf  "${payload}"
   echo $res
}

function vault-approle-login() {
  rolename="$1"
  shift

  role_id=$(vault-get-role-id "${rolename}"  | tr -d '"')
  secret_id=$(vault-get-role-secret-id "${rolename}"  | tr -d '"')

  postfix=$(echo $RANDOM | md5sum | head -c 20; echo;) 
  payload="/tmp/otp_role-${postfix}.json" 

  jq -n \
    --arg role_id $role_id \
    --arg secret_id $secret_id  \
    '{"role_id": $ARGS.named["role_id"],"secret_id": $ARGS.named["secret_id"]}' > "${payload}"
 
  curl \
    --silent \
    --request POST \
    --data @"${payload}" \
    "${VAULT_ADDR}/v1/auth/approle/login" | jq .auth.client_token | tr -d '"'
 
   sudo rm -rf  "${payload}"
}

t2m() {
  # t2m "6h"
  # t2m "3d 7h 5m"
  # t2m "7h"
   sed 's/d/*24*60 +/g; s/h/*60 +/g; s/m/\+/g; s/+[ ]*$//g' <<< "$1" | bc
}

#---------------------------------------------------------------
#  Getting input parameters
#---------------------------------------------------------------
while getopts s:n:g:t: flag
do
    case "${flag}" in
        s) server=${OPTARG};;
        n) username=${OPTARG};;
	    g) group=${OPTARG};;
        t) duration=${OPTARG};;
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

if [ -z "$duration" ]; then
   duration="5"
else
   duration=$(t2m "$duration")
fi

if [ -z "$group" ]; then
   group="$username"  
fi

#---------------------------------------------------------------
#  Vault login
#---------------------------------------------------------------
export VAULT_ADDR=${VAULT_ADDR:-http://172.31.44.220:8200}
export APP_TOKEN=$(vault-approle-login "otprole")
export VAULT_TOKEN=$APP_TOKEN

echo "vault token : $VAULT_TOKEN"
#---------------------------------------------------------------
# Creating a user name that people can't think of
#---------------------------------------------------------------
postfix=$(echo $RANDOM | md5sum | head -c 20; echo;)
username="${username}_${postfix}"

#---------------------------------------------------------------
# Set SSH Role  
#---------------------------------------------------------------
echo "Creating a otp role for temporary user.."

jq -n \
--arg cidr_list "0.0.0.0/0" \
--arg default_user "$username" \
--arg allowed_user "$username" \
--arg key_type "otp" \
--arg port 22 \
'{"cidr_list": $ARGS.named["cidr_list"],"default_user": $ARGS.named["default_user"],"allowed_user": $ARGS.named["allowed_user"],"key_type": $ARGS.named["key_type"],"port": $ARGS.named["port"]}' > "/tmp/otp_role_${username}.json"
 
vault-provision "ssh-client-onetime-pass/roles/otp_role_${username}" "/tmp/otp_role_${username}.json"

if [ ! $? == "0" ]; then
    echo "  failed to create a otp role for temporary user - otp_role_$username"
    exit 1
else 
    echo "  success to create a otp role for temporary user - otp_role_$username"
fi

#---------------------------------------------------------------
# Add a temporary user to target server
#---------------------------------------------------------------
echo "Creating a temporary user to target server.."

#addUserToRemoteServer.sh 
#   n) name
#   v) server
#   t) duration
#   d) directory (optional)
#   g) group (optional)
#   s) shell (optional)
#   r) vault_addr
#   k) vault_token
masterpass=$(vault-get-ssh-cred "ssh-client-onetime-pass/creds/otp_key_role" "$server") 
sshpass -p $masterpass ssh ubuntu@$server "bash -s" -- < ./addUserToRemoteServer.sh -n $username -v $server -g $group -t $duration -r $VAULT_ADDR -k $VAULT_TOKEN #&> /dev/null

if [ ! $? == "0" ]; then
    echo "  failed to add a new temporary user to target server - server: $server, username: $username"
    exit 1
else 
    echo "  success to add a new temporary user to target server - server: $server, username: $username"
fi

echo ""
echo ""	 
echo "Try : vault write ssh-client-onetime-pass/creds/otp_role_$username ip=$server"
echo "Try : ssh $username@$server" 
echo "Vaildation : $validtime"
