
##  Admin Server 에서 BationHost 에 접근 후 신규 유저 생성 및 SSH 설정
 
```console
$ sudo apt install jq
$ sudo apt install sshpass
$ chmod +x ./addUserToRemoteServer.sh
$ chmod +x ./userManagementToServer.sh
$ export VAULT_ADDR="http://172.31.44.220:8200"
$ export VAULT_TOKEN="hvs.zpu3IwU6OyNBg7iDN8DbWb3K"
$ ./userManagementToServer.sh -s <BASTION_SERVER_IP> -n <USER_NAME> -t <TIME>

ex> ./userManagementToServer.sh -s 172.31.43.91 -n 'daeung' -t '5m'
ex> ./userManagementToServer.sh -s 172.31.43.91 -n 'daeung' -t '5h 10m'
ex> ./userManagementToServer.sh -s 172.31.43.91 -n 'daeung' -t '2d 10h 10m'
```