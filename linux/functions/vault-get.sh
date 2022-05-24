#!/bin/bash -e
# Usage:
#   vault-get <path>
 
path=$(echo $1 | envsubst)
format=$(vault kv get -field=format $path 2> /dev/null)

if [ "base64" == "$format" ]
then
    vault kv get -field=value $path | base64 -D
else
    vault kv get -field=value $path
fi
