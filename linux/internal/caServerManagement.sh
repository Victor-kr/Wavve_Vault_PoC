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

function vault-read-ca() {
  path="$1"
  shift
  curl \
      --silent \
      --request GET \
      --header 'Accept: application/json'  \
      --header "X-Vault-Token: ${VAULT_TOKEN}" \
      "${VAULT_ADDR}/v1/${path}" | jq .data.public_key |  tr -d '"'
}

function backup-sshd-config(){
  file="$1"
  if [ -f ${file} ]
  then
    sudo cp ${file} ${file}.1
  else
    cho "File ${file} not found."
    exit 1
  fi
}

function edit-sshd-config() {
  file="$1"
  sudo sed -i '/^'"TrustedUserCAKeys"'/d' ${file}
  echo "TrustedUserCAKeys /etc/ssh/trusted-user-ca-keys.pem" | sudo tee -a ${file}
}
 
function reload-sshd(){
  sudo systemctl reload sshd.service
  echo "Run 'systemctl reload sshd.service'...OK"
}

#---------------------------------------------------------------
#  Getting input parameters
#---------------------------------------------------------------
while getopts f: flag
do
    case "${flag}" in
        f) sshd_config_file=${OPTARG};; 
    esac
done

if [ -z "$sshd_config_file" ]; then 
  echo '[Info] Config /etc/ssh/sshd_config ..'
  sshd_config_file="/etc/ssh/sshd_config"
else 
   echo '[Info] Config ${sshd_config_file}..'
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

cakey=$(vault-read-ca "ssh-client-signer/config/ca")
echo "New Key : $cakey"
echo $cakey | sudo tee /etc/ssh/trusted-user-ca-keys.pem

backup-sshd-config "${sshd_config_file}"
edit-sshd-config "${sshd_config_file}"
reload-sshd