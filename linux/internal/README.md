##  SSH CA - SSH Server(Internal Server)

SSH Server 는 아래 설정이 필요하고 이후 Bastion Host 에서 해당 SSH Server 에 접근할 수 있다. 
HTTPS 로 통신하는 경우 curl 명령에 -k 옵션을 붙이면 동작한다.

```console
$ export VAULT_ADDR="http://172.31.44.220:8200" 
$ sudo chmod +x ./caServerManagement.sh
$ ./caServerManagement.sh
```

