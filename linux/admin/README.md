
##  Admin Server 에서 BationHost 에 접근 후 신규 유저 생성 및 SSH 설정
 
```console
$ sudo apt install jq
$ sudo apt install sshpass
$ chmod +x ./addUserToRemoteServer.sh
$ chmod +x ./userManagementToServer.sh
$ export VAULT_ADDR="http://172.31.44.220:8200" 
$ ./userManagementToServer.sh -s <BASTION_SerVER_IP> -n <USER_NAME>
```

## [TODO] 

- ssh 롤 계속 생성하는게 아니라 ssh role 수정하는 형식? 가능한가?
- user.json 이 계속 사이즈가 커질건데 이건 어떻게?
- vault api 를 curl 로 수정 
