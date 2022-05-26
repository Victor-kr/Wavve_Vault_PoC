
## Vault SSH Helper 기본 SSH 설정 - BastionHost 에서 수행

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
ssh_mount_point = "ssh" 
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


## Vault SSH Helper 변경시는 아래 수행 - BastionHost 에서 수행

1. GoInstall.pdf 를 확인하여 Go 빌드 환경을 구성
2. 아래 과정을 통해 플러그인을 수정 후 빌드 : config 파일의 VAULT_ADDR 및 SSH_ROLE_NAME 은 상황에 맞게 구성
   - vault_addr = "http://<VAULT_ADDR>:8200"
   - ssh_mount_point = "<SSH_ROLE_NAME>" 
4. 설치

```console
$ mkdir go
$ cd go
$ git clone https://github.com/hashicorp/vault-ssh-helper.git
$ cd vault-ssh-helper
$ source ~/.profile

//소스 파일의 agent.go 파일을 수정 버전(Wavve/plugins/vault-ssh-helper/agent.go)으로 교체
//수정한 소스 파일의 DB 접근 경로를 수정 => [TODO] 환경변수로 빼야함
$ <agent.go 교체>

// MySQL Driver 다운로드
$ go get github.com/go-sql-driver/mysql

// Go 디펜던시 다운로드 및 빌드
$ go mod tidy
$ go build

// vault-ssh-helper 설치
$ sudo mv vault-ssh-helper /usr/bin
$ chmod +x /usr/bin/vault-ssh-helper

// vault-ssh-helper 구성(vault_add 및 ssh 마운트 포인트를 구성에 맞게 설정)
$ mkdir /root/vault
$ tee /root/vault/config.hcl <<EOF
vault_addr = "http://<VAULT_ADDR>:8200"
ssh_mount_point = "<SSH_ROLE_NAME>" 
tls_skip_verify = true
allowed_cidr_list="0.0.0.0/0"
allowed_roles = "*"
EOF

// Dev 모드로 실행 확인
$ sudo vault-ssh-helper -verify-only -config=/root/vault/config.hcl -dev

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
