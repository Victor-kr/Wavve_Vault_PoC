#!/bin/bash

#---------------------------------------------------------------
#  Getting input parameters
#---------------------------------------------------------------
while getopts n:v: flag
do
    case "${flag}" in
        n) name=${OPTARG};;
	      v) server=${OPTARG};;
    esac
done

#---------------------------------------------------------------
#  Checking input parameters
#---------------------------------------------------------------
if [ -z "$name" ]; then
    echo '[Error] Please put a user name to create a new temporary user to server.'
    exit 1   
fi

if [ -z "$server" ]; then
    echo '[Error] Please put a server host information.'
    exit 1 
fi
 
#---------------------------------------------------------------
#  Check user already exist
#---------------------------------------------------------------
if id "${name}" &>/dev/null; then
  echo "[Info] The user already exist -  ${name}"
  exit 2
fi


 
 