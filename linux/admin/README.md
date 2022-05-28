
##  SSH OTP 과정
 
Admin Server 에서 BationHost 에 접근 후 신규 유저를 생성 하고 SSH 접속을 위한 정보를 얻어낸 후 클라이언트에 전달하면 된다.

```console
$ sudo apt install jq
$ sudo apt install sshpass
$ chmod +x ./addUserToRemoteServer.sh
$ chmod +x ./userManagementToServer.sh

$ export VAULT_ADDR="http://172.31.44.220:8200"
$ vault login -method=userpass username=linuxadmin password=linuxadmin
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

$ export VAULT_TOKEN="hvs.CAESIJHL3EBy01oB7Lq2MJ5u2r9AxCRo76bJxwg_nF6rW_8RGh4KHGh2cy5NTHg3dWlpbjhzcVFzY01OeFhCYmx1czk"

$ ./userManagementToServer.sh -s <BASTION_SERVER_IP> -n <USER_NAME> -t <TIME>

ex> ./userManagementToServer.sh -s 172.31.43.91 -n 'daeung' -t '5m'
ex> ./userManagementToServer.sh -s 172.31.43.91 -n 'daeung' -t '5h 10m'
ex> ./userManagementToServer.sh -s 172.31.43.91 -n 'daeung' -t '2d 10h 10m'

ex> ./userManagementToServer.sh -s 172.31.43.91 -n 'daeung' -t '5m'  -u 'ubuntu' -h 'ssh-ca-role'
```