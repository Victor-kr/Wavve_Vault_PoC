#!/bin/bash


#---------------------------------------------------------------
# Functions
#---------------------------------------------------------------
function vault-put-secret() {
  path=$1
  shift
  payload="$*"

  set +e
    curl \
      --request POST \
      --header "X-Vault-Token: ${VAULT_TOKEN}" \
      --data @"${payload}" \
      "${VAULT_ADDR}/v1/${path}"
  set -e
}

function vault-get-secret() {
  path="$1"
  shift
  res=$(curl \
      --silent \
      --request GET \
      --header 'Accept: application/json'  \
      --header "X-Vault-Token: ${VAULT_TOKEN}" \
      "${VAULT_ADDR}/v1/${path}" | jq .data.data)
  echo $res
}

function vault-delete-secret() {
  path="$1"
  shift
  curl \
      --silent \
      --request DELETE \
      --header 'Accept: application/json'  \
      --header "X-Vault-Token: ${VAULT_TOKEN}" \
      "${VAULT_ADDR}/v1/${path}"
}

function vault-delete-role() {
  rolepath="$1"
  shift

  curl \
      --silent \
      --request DELETE \
      --header 'Accept: application/json'  \
      --header "X-Vault-Token: ${VAULT_TOKEN}" \
      "${VAULT_ADDR}/v1/${rolepath}"
}


#---------------------------------------------------------------
#  Getting input parameters
#---------------------------------------------------------------
while getopts n:t:v:d:g:s:r:k: flag
do
    case "${flag}" in
        n) name=${OPTARG};;
	      v) server=${OPTARG};;
        t) duration=${OPTARG};;
        d) directory=${OPTARG};;
        g) group=${OPTARG};;
	      s) shell=${OPTARG};; 
        r) vault_addr=${OPTARG};; 
        k) vault_token=${OPTARG};; 
    esac
done

#---------------------------------------------------------------
#  Checking input parameters
#---------------------------------------------------------------
if [ -z "$name" ]; then
    echo '[Error] Please put a user name to create a new temporary user to server.'
    exit 1  
else
    echo '[Info] Starting add a new tempory user to server.'
fi

if [ -z "$server" ]; then
    echo '[Error] Please put a server host information.'
    exit 1 
fi

if [ -z "$vault_addr" ]; then
    echo '[Error] Please put vault address information.'
    exit 1 
fi

if [ -z "$vault_token" ]; then
    echo '[Error] Please put vault token information.'
    exit 1 
fi

if [ -z "$duration" ]; then
    duration=
fi

if [ -z "$directory" ]; then
   directory="/home/${name}" 
fi

if [ -z "$group" ]; then
   group="$name"  
fi

if [ -z "$shell" ]; then
   shell="/bin/sh"
fi

export VAULT_ADDR=${vault_addr}
export VAULT_TOKEN=${vault_token}

#---------------------------------------------------------------
#  Check jq & at command installed
#--------------------------------------------------------------- 
programs="jq at curl"
for p in programs; do
  if which jq >/dev/null; then
    echo "${p} already installed"
  else
    if command -v apt >/dev/null; then
      sudo apt update 
      sudo apt install $p -y
    elif command -v apt-get >/dev/null; then
      sudo apt-get update 
      sudo apt-get install $p -y
    elif command -v yum >/dev/null; then
      sudo yum install  $p -y 
    fi
  fi
done

#---------------------------------------------------------------
#  Check user already exist
#---------------------------------------------------------------
if id "${name}" &>/dev/null; then
  echo "[Info] User already exist -  ${name}"
  exit 0
fi


#---------------------------------------------------------------
# Check already a published user
#---------------------------------------------------------------
res=$(vault-get-secret "tempusers/data/linux/${server}/users/${name}")  
if [ "$res" == "" ]; then
  echo "[Info] User name already used -  ${name}"
  exit 1
fi

#---------------------------------------------------------------
#  Creating user and group
#---------------------------------------------------------------
if [ id "$name" &>/dev/null ]; then # Check user already exists
    echo '[Info] User exist.'
    exit 0
else
    echo '[Info] User not exist.'
fi

if [ $(getent group ${group}) ]; then # Create Group if group not exist
  echo "[Info] Group exists -  ${group}"
else
  echo "[Info] Creating group - ${group}"
  sudo groupadd $group
  res=$?
  if [ $res -eq 0 ]; then
    echo "[Info] Succeed to groupadd -  ${group}"      
  else
    echo "[Error] Failed to groupadd command -  ${group}"
    exit 1
  fi  
fi

sudo useradd -d "${directory}" -m  -g "${group}" -s "${shell}" "${name}" # Add a new user to server
res=$?
if [ $res -eq 0 ]; then
  echo "[Info] Succeed to useradd -  ${name}"      
else
  echo "[Error] Failed to useradd-  ${name}"
  exit 1
fi

#---------------------------------------------------------------
# Write user information to vault
#---------------------------------------------------------------
jq -n --arg name "${name}" \
--arg directory "${directory}"  \
--arg group "${group}"  \
--arg shell "${shell}" \
'{"data": [{"name": $ARGS.named["name"],"directory": $ARGS.named["directory"],"group": $ARGS.named["group"],"shell": $ARGS.named["shell"]}]}' > "/tmp/userinfo_${name}.json"

vault-put-secret  "tempusers/data/linux/${server}/users/${name}" "/tmp/userinfo_${name}.json"


#---------------------------------------------------------------
# Delete temporary user after period 
# [TODO]
#    otp role 삭제
#    secret 삭제
#---------------------------------------------------------------
cat <<EOF | at now + ${duration} minutes
  sudo userdel -f -r $name
  vault-delete-role "ssh-client-onetime-pass/roles/otp_role_${name}"
  vault-delete-secret "tempusers/metadata/linux/${server}/users/${name}"
EOF

#---------------------------------------------------------------
# Print Result
#---------------------------------------------------------------
id "$name"
getent group $group
atq