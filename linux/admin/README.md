
##  Admin Server 에서 BationHost 에 접근 후 신규 유저 생성 및 SSH 설정
 
```console
$ sudo apt install jq
$ sudo apt install sshpass
$ chmod +x ./addUserToRemoteServer.sh
$ chmod +x ./userManagementToServer.sh

$vault login -method=userpass \
    username=linuxadmin \
    password=linuxadmin
Key                    Value
---                    -----
token                  hvs.CAESIJHL3EBy01oB7Lq2MJ5u2r9AxCRo76bJxwg_nF6rW_8RGh4KHGh2cy5NTHg3dWlpbjhzcVFzY01OeFhCYmx1czk
token_accessor         ifowHRSNXjgdUKQ97cBCcg18
token_duration         768h
token_renewable        true
token_policies         ["admin-policy" "default"]
identity_policies      []
policies               ["admin-policy" "default"]
token_meta_username    linuxadmin

$ export VAULT_ADDR="http://172.31.44.220:8200"
$ export VAULT_TOKEN="hvs.CAESIJHL3EBy01oB7Lq2MJ5u2r9AxCRo76bJxwg_nF6rW_8RGh4KHGh2cy5NTHg3dWlpbjhzcVFzY01OeFhCYmx1czk"

$ ./userManagementToServer.sh -s <BASTION_SERVER_IP> -n <USER_NAME> -t <TIME>

ex> ./userManagementToServer.sh -s 172.31.43.91 -n 'daeung' -t '5m'
ex> ./userManagementToServer.sh -s 172.31.43.91 -n 'daeung' -t '5h 10m'
ex> ./userManagementToServer.sh -s 172.31.43.91 -n 'daeung' -t '2d 10h 10m'
```