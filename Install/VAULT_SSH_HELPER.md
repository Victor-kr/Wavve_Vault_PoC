
## Bastion Server 에 SSH Helper 설치

- 사전에 env provision 필요


### 필요한 파일 전달

```
scp -i ~/.ssh/poc-test.pem -pv ~/vault-ssh-helper ubuntu@10.13.42.102:/home/ubuntu/vault-ssh-helper
```

### Vault-SSH-Helper 설치

```console
// 접속할 사용자 생성
$ sudo su

// vault-ssh-helper 다운로드 및 설치
$ wget https://releases.hashicorp.com/vault-ssh-helper/0.2.1/vault-ssh-helper_0.2.1_linux_amd64.zip
$ unzip vault-ssh-helper_0.2.1_linux_amd64.zip
$ mv vault-ssh-helper /usr/bin
$ chmod +x /usr/bin/vault-ssh-helper

// vault-ssh-helper 구성, tls 가 없으면 dev 로만 동작하
$ mkdir /root/vault
$ tee /root/vault/config.hcl <<EOF
vault_addr = "http://172.31.37.26:8200"
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
