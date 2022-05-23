
# Vault SSH Helper 설치 - BastionHost 에서 수행

1. GoInstall.pdf 를 확인하여 Go 빌드 환경을 구성
2. 아래 과정을 통해 플러그인을 수정 후 빌드
3. 설치

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
vault_addr = "http://172.31.37.26:8200"
ssh_mount_point = "ssh-client-onetime-pass" 
tls_skip_verify = true
allowed_cidr_list="0.0.0.0/0"
allowed_roles = "*"
EOF

// Dev 모드로 실행 확인
$ sudo vault-ssh-helper -verify-only -config=/root/vault/config.hcl -dev
```
