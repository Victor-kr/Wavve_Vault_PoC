
# Vault SSH Helper 수정

GoInstall.pdf 를 확인하여 Go 빌드 환경을 구성하고 아래 과정을 통해 수정 플러그인을 빌드한다.

```
$ mkdir go
$ cd go
$ git clone https://github.com/hashicorp/vault-ssh-helper.git
$ cd vault-ssh-helper
$ source ~/.profile
$ 소스 파일의 agent.go 파일을 수정 버전(Wavve/plugins/vault-ssh-helper/agent.go)으로 교체
$ 수정한 소스 파일의 DB 접근 경로를 수정 => [TODO] 환경변수로 빼야함
$ go mod tidy
$ go build
```
