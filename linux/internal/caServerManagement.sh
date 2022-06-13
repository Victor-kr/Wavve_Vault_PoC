#!/bin/bash

#---------------------------------------------------------------
# Functions
#---------------------------------------------------------------
function curlWapper() {
  url="${@: -1}"
  if [[ $url = https://* ]]; then
    curl -k $*
  else
    curl $*
  fi
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

sudo rm -rf /etc/ssh/trusted-user-ca-keys.pem
curlWapper -o ${HOME}/trusted-user-ca-keys.pem ${VAULT_ADDR}/v1/ssh-client-signer/public_key
sudo mv ${HOME}/trusted-user-ca-keys.pem /etc/ssh/trusted-user-ca-keys.pem

backup-sshd-config "${sshd_config_file}"
edit-sshd-config "${sshd_config_file}"
reload-sshd
