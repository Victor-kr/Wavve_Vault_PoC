
##  SSH OTP 과정
 
Admin Server 에서 BationHost 에 접근 후 신규 유저를 생성 하고 SSH 접속을 위한 정보를 얻어낸 후 클라이언트에 전달하면 된다.

```console  
$ export VAULT_ADDR="[http://172.31.44.220:8200](http://internal-poc-vault-alb-1279828201.ap-northeast-2.elb.amazonaws.com:443)"
$ curl --request POST --data '{"password": "linuxadmin"}' $VAULT_ADDR/v1/auth/userpass/login/linuxadmin
 
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
```

Admin Server 에서 BationHost 에 접근 후 신규 유저를 생성 하고 SSH 접속을 위한 정보를 얻어낸 후 클라이언트에 전달하면 된다.

Internal 서버에 설정한 Role 이름을 같이 전달하면 SSH CA 설정도 같이 해준다.

```console  
// userManagementToServer.sh 옵션구성
//   s(required) server 
//   n(required) username 
//   g(optional) group (default : username)
//   t(optional) duration (default : 5m)
//   u(optional) ssh_user 
//   h(optional) ssh_ca_role 
$ ./userManagementToServer.sh -s <BASTION_SERVER_IP> -n <USER_NAME> -g <GROUP_NAME> -t <TIME>  -u <SSH-USER> -h <SSH-ROLE_NAME>
ex> ./userManagementToServer.sh -s 172.31.43.91 -n 'daeung' -t '5m'
ex> ./userManagementToServer.sh -s 172.31.43.91 -n 'daeung' -t '5h 10m'
ex> ./userManagementToServer.sh -s 172.31.43.91 -n 'daeung' -t '2d 10h 10m' 
ex> ./userManagementToServer.sh -s 172.31.43.91 -n 'daeung' -t '5m'  -u 'ubuntu' -h 'ssh-ca-role'
```
