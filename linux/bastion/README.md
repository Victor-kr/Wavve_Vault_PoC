
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
// SSH Key Pair 연결 확인
$ ssh -i ~/.ssh/id_rsa_cert.pub -i ~/.ssh/id_rsa ubuntu@<web-server-ip>
Welcome to Ubuntu 20.04.4 LTS (GNU/Linux 5.13.0-1022-aws x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  System information as of Mon May 16 09:52:10 UTC 2022

  System load:  0.16              Processes:             113
  Usage of /:   24.0% of 7.69GB   Users logged in:       1
  Memory usage: 23%               IPv4 address for eth0: 172.31.43.32
  Swap usage:   0%


41 updates can be applied immediately.
24 of these updates are standard security updates.
To see these additional updates run: apt list --upgradable


Last login: Mon May 16 09:30:24 2022 from 219.240.45.245
ubuntu@ip-172-31-43-32:~$
```