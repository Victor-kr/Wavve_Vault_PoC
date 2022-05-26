
##  Admin Server 에서 BationHost 에 접근 후 신규 유저 생성 및 SSH 설정
 
```console
$ sudo apt install jq
$ sudo apt install sshpass
$ chmod +x ./addUserToRemoteServer.sh
$ chmod +x ./userManagementToServer.sh

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

$ export VAULT_ADDR="http://172.31.44.220:8200"
$ export VAULT_TOKEN="hvs.CAESIJHL3EBy01oB7Lq2MJ5u2r9AxCRo76bJxwg_nF6rW_8RGh4KHGh2cy5NTHg3dWlpbjhzcVFzY01OeFhCYmx1czk"

$ ./userManagementToServer.sh -s <BASTION_SERVER_IP> -n <USER_NAME> -t <TIME>

ex> ./userManagementToServer.sh -s 172.31.43.91 -n 'daeung' -t '5m'
ex> ./userManagementToServer.sh -s 172.31.43.91 -n 'daeung' -t '5h 10m'
ex> ./userManagementToServer.sh -s 172.31.43.91 -n 'daeung' -t '2d 10h 10m'
```

##  SSH CA 과정

Admin 에서 CA Sign 이 가능한 Token 을 발행한다.

```console 
$ vault login -method=userpass username=casigner password=casigner
```

web 서버에 Vault CA 를 설정한다.

```console
// Vault 설치
$ sudo su
$ curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
$ sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
$ sudo apt-get update && sudo apt-get install vault

# Vault CA 의 Public Key 를 받아와서 sshd 에 설정
$ export VAULT_ADDR=http://172.31.37.26:8200
$ export VAULT_TOKEN="hvs.CAESIIwTkyH3roN33TdpQoBmc0gJ4iDP80p0gePc7wrIxYoAGh4KHGh2cy5oS3I1akJ6dUw5M1FFT0pUZkdya2dqdGY"
$ vault read -field=public_key ssh-client-signer/config/ca > /etc/ssh/trusted-user-ca-keys.pem
$ vi /etc/ssh/sshd_config
 ...
TrustedUserCAKeys /etc/ssh/trusted-user-ca-keys.pem

$ systemctl restart sshd
```

bastion 호스트에서 CA Role 을 발행하고 저장한다.

```console
// Vault 설치
$ sudo su
$ curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
$ sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
$ sudo apt-get update && sudo apt-get install vault

# Vault CA Private Key 로 자신의 Public Key 를 Sign
$ su - ubuntu
$ export VAULT_ADDR=http://172.31.37.26:8200
$ export VAULT_TOKEN="hvs.CAESIIwTkyH3roN33TdpQoBmc0gJ4iDP80p0gePc7wrIxYoAGh4KHGh2cy5oS3I1akJ6dUw5M1FFT0pUZkdya2dqdGY"
$ ssh-keygen -t rsa  
$ vault write -field=signed_key ssh-client-signer/sign/ssh-ca-role \
  public_key=@/home/ubuntu/.ssh/id_rsa.pub > /home/ubuntu/.ssh/id_rsa_cert.pub
$ chmod 600 ~/.ssh/id_rsa
$ chmod 644 ~/.ssh/id_rsa.pub  
$ chmod 644 ~/.ssh/id_rsa_cert.pub
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