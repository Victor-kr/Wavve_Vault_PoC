#!/bin/bash


#---------------------------------------------------------------
# Functions
#---------------------------------------------------------------
function vault-put-secret() {
  path=$1
  shift
  payload="$*"

  set +e
    curl -k \
      --request POST \
      --header "X-Vault-Token: ${VAULT_TOKEN}" \
      --data @"${payload}" \
      "${VAULT_ADDR}/v1/${path}"
  set -e
}

function vault-get-secret() {
  path="$1"
  shift
  curl -k \
      --silent \
      --request GET \
      --header 'Accept: application/json'  \
      --header "X-Vault-Token: ${VAULT_TOKEN}" \
      "${VAULT_ADDR}/v1/${path}" | jq .data.data
}

function vault-delete-secret() {
  path="$1"
  shift
  curl -k \
      --silent \
      --request DELETE \
      --header 'Accept: application/json'  \
      --header "X-Vault-Token: ${VAULT_TOKEN}" \
      "${VAULT_ADDR}/v1/${path}"
}

function vault-delete-role() {
  rolepath="$1"
  shift

  curl -k \
      --silent \
      --request DELETE \
      --header 'Accept: application/json'  \
      --header "X-Vault-Token: ${VAULT_TOKEN}" \
      "${VAULT_ADDR}/v1/${rolepath}"
}

function vault-get-role-id() {
  path="$1"
  shift
  res=$(curl -k \
      --silent \
      --request GET \
      --header 'Accept: application/json'  \
      --header "X-Vault-Token: ${VAULT_TOKEN}" \
      "${VAULT_ADDR}/v1/${path}/role-id" | jq .data.role_id)
  echo $res
}

function vault-get-role-secret-id() {
  path="$1"
  shift
  res=$(curl -k \
      --silent \
      --request POST \
      --header 'Accept: application/json'  \
      --header "X-Vault-Token: ${VAULT_TOKEN}" \
      "${VAULT_ADDR}/v1/${path}/secret-id" | jq .data.secret_id)
  echo $res
}

function vault-approle-login() {
  rolename="$1"
  shift 
 
  # role-id 및 secret-id 얻음
  role_id=$(vault-get-role-id "auth/approle/role/${rolename}"  | tr -d '"')
  secret_id=$(vault-get-role-secret-id "auth/approle/role/${rolename}"  | tr -d '"')
 
  postfix=$(echo $RANDOM | md5sum | head -c 20; echo;) 
  payload="/tmp/app_role_${rolename}_${postfix}.json" 

  jq -n \
    --arg role_id $role_id \
    --arg secret_id $secret_id  \
    '{"role_id": $ARGS.named["role_id"],"secret_id": $ARGS.named["secret_id"]}' > "${payload}"
 
  curl -k \
    --silent \
    --request POST \
    --data @"${payload}" \
    "${VAULT_ADDR}/v1/auth/approle/login" | jq .auth.client_token | tr -d '"'
 
   sudo rm -rf  "${payload}"
}

function create-ssh-key() {
  username=$1
  shift   
  group=$1
  shift     
  directory=$1
  shift 
  ssh_ca_role=$1
  shift   
  ssh_user="$*"

  key_file="${directory}/.ssh/id_rsa_${ssh_ca_role}_${ssh_user}"
  sudo rm -rf "${key_file}"
  sudo rm -rf "${key_file}.pub"
  sudo rm -rf "${key_file}_cert.pub" 

  sudo ssh-keygen -t rsa-sha2-256 -N "" -C "${ssh_user}" -f "${key_file}"

  sudo chown "${username}:${group}" "${key_file}"
  sudo chown "${username}:${group}" "${key_file}.pub"
  
  sudo chmod 400 "${key_file}"
  sudo chmod 400 "${key_file}.pub"  
}

function vault-sign-ssh-key() {
  username=$1
  shift   
  group=$1
  shift       
  directory=$1
  shift 
  ssh_ca_role=$1
  shift   
  ssh_user="$*"

  key_file="${directory}/.ssh/id_rsa_${ssh_ca_role}_${ssh_user}"
  public_key=$(sudo cat ${key_file}.pub)
  

  postfix=$(echo $RANDOM | md5sum | head -c 20; echo;)
  payload="/tmp/sign-ssh-key-${postfix}.json"

  jq -n \
    --arg public_key "$public_key" \
    --arg valid_principals "$ssh_user" \
    '{"public_key": $ARGS.named["public_key"],"valid_principals": $ARGS.named["valid_principals"]}' > "${payload}"

  res=$(curl -k \
    --silent \
    --request POST \
    --header "X-Vault-Token: ${VAULT_TOKEN}" \
    --data @"${payload}" \
    "${VAULT_ADDR}/v1/ssh-client-signer/sign/${ssh_ca_role}"  | jq .data.signed_key | tr -d '"' | tr -d '\n')

  sudo rm -rf  "${payload}"
  
  res=${res%$'\n'} #후행 줄바꿈 제거
  res=${res/%??/} #후행 줄바꿈 문자 제거

  echo $res | sudo tee "${key_file}_cert.pub" 
  sudo chown "${username}:${group}" "${key_file}_cert.pub"
  sudo chmod 400 "${key_file}_cert.pub" 

  echo "SIGN KEY: "
  sudo cat "${key_file}_cert.pub"
}


#---------------------------------------------------------------
#  Getting input parameters
#---------------------------------------------------------------
while getopts n:t:v:d:g:s:r:k:u:h: flag
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
        u) ssh_user=${OPTARG};; 
        h) ssh_ca_role=${OPTARG};; 
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
    duration=60
fi

if [ -z "$directory" ]; then
   directory="/home/${name}" 
fi

if [ -z "$group" ]; then
   group="$name"  
fi

if [ -z "$shell" ]; then
   shell="/bin/bash"
fi

#---------------------------------------------------------------
#  Check user already exist
#---------------------------------------------------------------
if id "${name}" &>/dev/null; then
  echo "[Info] The temporary user already used -  ${name}"
  exit 1
fi
 

#---------------------------------------------------------------
#  Check jq & at command installed
#--------------------------------------------------------------- 
programs=("jq" "at" "curl")
for program in "${programs[@]}"; do
  if which "${program}" >/dev/null; then
    echo "${program} already installed" 
  else
    echo "${program} is not installed. please install this package.."
  fi
done

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

sudo chown "${name}:${group}" "${directory}" 
sudo chmod 777 "${directory}"

sudo mkdir "${directory}/.ssh" 
sudo chown "${name}:${group}" "${directory}/.ssh" 
sudo chmod 777 "${directory}/.ssh" 

#---------------------------------------------------------------
# Write user information to vault
#---------------------------------------------------------------
export VAULT_ADDR="${vault_addr}"
export VAULT_TOKEN="${vault_token}"

jq -n --arg name "${name}" \
--arg directory "${directory}"  \
--arg group "${group}"  \
--arg shell "${shell}" \
'{"data": [{"name": $ARGS.named["name"],"directory": $ARGS.named["directory"],"group": $ARGS.named["group"],"shell": $ARGS.named["shell"]}]}' > "/tmp/userinfo_${name}.json"

vault-put-secret  "tempusers/data/linux/${server}/users/${name}" "/tmp/userinfo_${name}.json"


#---------------------------------------------------------------
# Delete temporary user after period  
#---------------------------------------------------------------
cat <<EOF | sudo at now + ${duration} minutes 
  sudo chmod +x /home/ubuntu/cleanResources.sh
  /home/ubuntu/cleanResources.sh  -n "${name}" -s "${server}" -r "${VAULT_ADDR}" -k "${VAULT_TOKEN}"
EOF


if [[ -z "$ssh_user" || -z "${ssh_ca_role}" ]]; then 
  sudo id "$name"
  sudo getent group $group
  sudo atq
else
  echo 'Checking CA Process : ${ssh_ca_role} ,CaUser : "${ssh_user}'
  create-ssh-key "${name}" "${group}" "${directory}" "${ssh_ca_role}" "${ssh_user}"
  vault-sign-ssh-key "${name}" "${group}" "${directory}" "${ssh_ca_role}" "${ssh_user}"
fi 

sudo chmod 700 "${directory}" 
sudo chmod 700 "${directory}/.ssh"
