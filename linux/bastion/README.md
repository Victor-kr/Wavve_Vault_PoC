##  SSH CA - Client(Bastion)
 
Bastion Host 에서 Internal Server 로 접근시는 Vault CA 를 사용한다.

```console
$ export VAULT_ADDR="http://172.31.44.220:8200"
$ export VAULT_TOKEN="hvs.zpu3IwU6OyNBg7iDN8DbWb3K"
$ chmod +x ./caClientManagement.sh
$ ./caClientManagement.sh -s 172.31.43.32 -k myTestkey
```
 
이제 bastion 호스트에서 web 서버로 접근시 key pair 를 이용하여 접속 가능하다.

```console
$ ssh -i ~/.ssh/myTestkey_cert.pub -i ~/.ssh/myTestkey ubuntu@172.31.43.32
```