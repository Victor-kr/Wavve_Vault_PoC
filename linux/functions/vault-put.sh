#!/bin/bash 
# Usage:
#   vault-put <path> [<secret vaule> | @<secret file>]

path=$1
shift
secret="$*"
if [ -z "$secret" ]
then
   echo "secret vaule(file) is empty"
  exit 1
fi

if [[ "$secret" =~ ^@ ]];
then
    f=$(echo $secret | cut -c 2-)
    if file -b -I $f | grep -s binary > /dev/+
    then
        v=$(cat $f | base64)
        format=base64
    else
        v=$(cat $f)
        format=text
    fi
else
    v=$secret
    format=text
fi
 
vault kv get "$path" | tee /tmp/$(basename $path).$$
if [[ -f /tmp/$(basename $path).$$ ]] && [[ -s /tmp/$(basename $path).$$ ]] ; then
    echo "Replace existing secret data"
fi
vault kv put "$path" value="$v" format="$format"
