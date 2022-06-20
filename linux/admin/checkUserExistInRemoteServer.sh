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
#  Check user already exist
#---------------------------------------------------------------
if id "${name}" &>/dev/null; then
  echo "userExist"
  exit 0
fi

echo "userNotExist"
