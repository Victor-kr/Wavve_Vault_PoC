#!/bin/bash


#---------------------------------------------------------------
# Functions
#---------------------------------------------------------------
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
while getopts n:r:k:s: flag
do
    case "${flag}" in
        n) name=${OPTARG};;
        s) server=${OPTARG};;
        r) vault_addr=${OPTARG};;
        k) vault_token=${OPTARG};;
    esac
done

#---------------------------------------------------------------
#  Checking input parameters
#---------------------------------------------------------------
if [ -z "$name" ]; then
    exit 1
fi

if [ -z "$vault_addr" ]; then
    exit 1
fi

if [ -z "$vault_token" ]; then
    exit 1
fi

#export VAULT_ADDR='http://172.31.44.220:8200'
#export VAULT_TOKEN='hvs.zpu3IwU6OyNBg7iDN8DbWb3K'

export VAULT_ADDR="${vault_addr:-http://172.31.44.220:8200}"
export VAULT_TOKEN="${vault_token:-hvs.zpu3IwU6OyNBg7iDN8DbWb3K}"

#---------------------------------------------------------------
#  Cleaning
#---------------------------------------------------------------
servername="${server//./_}" 
sudo userdel -f -r $name
vault-delete-role "ssh-client-onetime-pass/roles/otp_role_${servername}_${name}"
vault-delete-secret "tempusers/metadata/linux/${server}/users/${name}"
