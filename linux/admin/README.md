
##  Admin Server 에서 BationHost 에 접근 후 신규 유저 생성 및 SSH 설정
 
```console
$ chmod +x ./addUserToRemoteServer.sh
$ chmod +x ./userManagementToServer.sh
$ export VAULT_ADDR="http://172.31.37.26:8200"
$ export VAULT_TOKEN="hvs.zpu3IwU6OyNBg7iDN8DbWb3K"
$ ./userManagementToServer.sh -s 172.31.43.91 -n <USER_NAME>
```

## [TODO] 

- ssh 롤 계속 생성하는게 아니라 user 추가하는 형식으로 수정
- vault api 를 curl 로 수정 
