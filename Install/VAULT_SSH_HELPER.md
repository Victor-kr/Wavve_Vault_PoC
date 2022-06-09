
## Bastion Server 에 SSH Helper 설치

- 사전에 env provision 필요


### 필요한 파일 전달

```
$ wget https://releases.hashicorp.com/vault-ssh-helper/0.2.1/vault-ssh-helper_0.2.1_linux_amd64.zip
$ unzip vault-ssh-helper_0.2.1_linux_amd64.zip
$ scp -i ~/.ssh/poc-test.pem -pv ~/vault-ssh-helper ubuntu@10.13.42.102:/home/ubuntu/vault-ssh-helper
```

### Vault-SSH-Helper 설치

```console
$ sudo su
$ mv vault-ssh-helper /usr/bin
$ chmod +x /usr/bin/vault-ssh-helper

// vault-ssh-helper 구성
$ mkdir /root/vault
$ tee /root/vault/config.hcl <<EOF
vault_addr = "http://10.13.42.202:8200"
ssh_mount_point = "ssh-client-onetime-pass" 
tls_skip_verify = true
allowed_cidr_list="0.0.0.0/0"
allowed_roles = "*"
EOF

// vault-ssh-helper 구성 테스트
$ vault-ssh-helper -verify-only -config=/root/vault/config.hcl -dev
2021/10/18 06:25:40 ==> WARNING: Dev mode is enabled!
2021/10/18 06:25:40 [INFO] using SSH mount point: ssh
2021/10/18 06:25:40 [INFO] using namespace:
2021/10/18 06:25:40 [INFO] vault-ssh-helper verification successful!
```

### SSH 구성 설정

```console
// 리눅스 표준 SSH 모듈인 common-auth 를 주석 처리
// 인증시 vault-ssh-helper 를 사용하도록 설정
$ vi /etc/pam.d/sshd  
# Standard Un*x authentication.
#@include common-auth
auth requisite pam_exec.so quiet expose_authtok log=/tmp/vaultssh.log /usr/bin/vault-ssh-helper -config=/root/vault/config.hcl -dev
auth optional pam_unix.so not_set_pass use_first_pass nodelay
...

$ vi /etc/ssh/sshd_config
ChallengeResponseAuthentication yes
UsePAM yes
PasswordAuthentication no

$ sudo systemctl restart sshd
```


