#!/bin/bash

#---------------------------------------------------------------
#  Getting input parameters
#---------------------------------------------------------------
while getopts n:d:g:s: flag
do
    case "${flag}" in
        n) name=${OPTARG};;
        d) directory=${OPTARG};;
        g) group=${OPTARG};;
	s) shell=${OPTARG};;
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

if [ -z "$directory" ]; then
   directory="/home/${name}" 
fi

if [ -z "$group" ]; then
   group="$name"  
fi

if [ -z "$shell" ]; then
   shell="/bin/sh"
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
  echo "[Error] Failed to useradd command -  ${name}"
fi


#---------------------------------------------------------------
# Write user information to json file
#---------------------------------------------------------------
Dir="/usr/local/share/tempuser"
File="${Dir}/user.json"
TemplateFile="${Dir}/user_temp.json"

if ! [ -d "${Dir}" ]; then
  sudo  mkdir -p $Dir
  sudo chmod 777 $Dir
fi

if ! [ -f "${TemplateFile}" ]; then
  sudo cat <<EOF > ${TemplateFile}
{
  "users": [
  ]
}
EOF
  sudo chmod 777 $TemplateFile
fi

if ! [ -f "${File}" ]; then
  sudo touch $File
  sudo chmod 777 $File
  jq ".users[.users| length] |= . + {\"name\":\"${name}\",\"directory\":\"${directory}\",\"group\":\"${group}\",\"shell\":\"${shell}\"}"  $TemplateFile >> $File
else
  # Check whether user information already exists.
  checkItem=$(cat /usr/local/share/tempuser/user.json | jq -c ".users[] | select(.name | contains(\"${name}\"))")

  if [ -z "${checkItem}" ]; then # If not exist user inforamtion in the user file
    echo "[Info] Add a new information to file -  ${name}"

    sudo rm -rf $TemplateFile
    jq ".users[.users| length] |= . + {\"name\":\"${name}\",\"directory\":\"${directory}\",\"group\":\"${group}\",\"shell\":\"${shell}\"}"  $File >> $TemplateFile
    sudo rm -rf $File
    sudo cp $TemplateFile $File
  else   # If exist user inforamtion in the user file
    echo "[Error] There are user information already in the user.json file -  ${name}"
    exit 1
  fi
fi

#---------------------------------------------------------------
# Print Result
#---------------------------------------------------------------
id "$name"
getent group $group
cat $File
