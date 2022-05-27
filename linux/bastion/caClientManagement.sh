#!/bin/bash

#---------------------------------------------------------------
# Functions
#---------------------------------------------------------------
function vault-get-role-id() {
  path="$1"
  shift
  res=$(curl \
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
  res=$(curl \
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
 
  curl \
    --silent \
    --request POST \
    --data @"${payload}" \
    "${VAULT_ADDR}/v1/auth/approle/login" | jq .auth.client_token | tr -d '"'
 
   sudo rm -rf  "${payload}"
}

function vault-sign-ssh-key() {
  path=$1
  shift
  ssh_user="$*"
  shift 


  key_file="${HOME}/.ssh/id_rsa_${ssh_user}"
  public_key=$(cat ${key_file}.pub)
  echo "PUBLIC KEY : $public_key"

  postfix=$(echo $RANDOM | md5sum | head -c 20; echo;)
  payload="/tmp/sign-ssh-key-${postfix}.json"

  jq -n \
    --arg public_key "$public_key" \
    --arg valid_principals "$ssh_user" \
    '{"public_key": $ARGS.named["public_key"],"valid_principals": $ARGS.named["valid_principals"]}' > "${payload}"

  res=$(curl \
    --silent \
    --request POST \
    --header "X-Vault-Token: ${VAULT_TOKEN}" \
    --data @"${payload}" \
    "${VAULT_ADDR}/v1/${path}"  | jq .data.signed_key | tr -d '"')

  sudo rm -rf  "${payload}"
   
  echo $res | sudo tee "${key_file}_cert.pub"

  sudo chmod 600 "${key_file}"
  sudo chmod 644 "${key_file}.pub"
  sudo chmod 644 "${key_file}_cert.pub" 
}

#---------------------------------------------------------------
#  Getting input parameters
#---------------------------------------------------------------
while getopts s:u: flag
do
    case "${flag}" in
        s) server=${OPTARG};;
        u) ssh_user=${OPTARG};; 
    esac
done

if [ -z "$sshd_config_file" ]; then 
  echo '[Info] Config /etc/ssh/sshd_config ..'
  sshd_config_file="/etc/ssh/sshd_config"
else 
   echo '[Info] Config ${sshd_config_file}..'
fi

if [ -z "$ssh_user" ]; then 
  echo '[Error] Please put a user name to create key'
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
    if command -v apt >/dev/null; then
      sudo apt update 
      sudo apt install -y "${program}"
    elif command -v apt-get >/dev/null; then
      sudo apt-get update 
      sudo apt-get install -y "${program}"
    elif command -v yum >/dev/null; then
      sudo yum install -y "${program}"
    fi
  fi
done

#---------------------------------------------------------------
#  Main
#---------------------------------------------------------------
export VAULT_ADDR=${VAULT_ADDR:-http://172.31.44.220:8200}
export APP_TOKEN=$(vault-approle-login "carole")
export VAULT_TOKEN=$APP_TOKEN

key_file="${HOME}/.ssh/id_rsa_${ssh_user}"

ssh-keygen -t rsa-sha2-256 -N "" -C "${ssh_user}" -f "${key_file}"

vault-sign-ssh-key "ssh-client-signer/sign/ssh-ca-role" "${ssh_user}"

echo "Trying.... ssh -i .ssh/id_rsa_${ssh_user}_cert.pub -i .ssh/id_rsa_${ssh_user} ${ssh_user}@${server}"
