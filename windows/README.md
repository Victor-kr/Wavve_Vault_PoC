# wavePOC

## Window 가상 시나리오

- 클라이언트 
	- 임시 사용자 생성 기능
		1. 클라이언트에서 임시 사용자 생성 요청
		2. 클라이언트에서 원격 서버 연결 후 임시 사용자 생성 
		3. 임시 사용자에 vault-secrets-gen 사용하여 랜덤 패스워드 생성 및 유저에 할당  
		4. vault 에 사용자에 대한 cred 정보 생성
	- 기존 사용자 임시 패스워드 부여
		1. 클라이언트 UI 에서 기존 사용자 조회  
		2. 기존 사용자에 vault-secrets-gen 사용하여 랜덤 패스워드 생성 및 유저에 할당  
		3. vault 에 사용자에 대한 cred 정보 업데이트
- 서버 
	- 현재 로그인한 사용자에 대해 신규 패스워드 발급 기능 
		1. 현재 로그인한 사용자에 대해  vault-secrets-gen 사용하여 랜덤 패스워드 생성 및 유저에 할당   
		2. vault 에 사용자에 대한 cred 정보 업데이트


### Windows Client

- RenewPassClient.bat 파일을 바탕화면으로 옮기고 이를 실행

## Linux 가상 시나리오
- 클라이언트 
- 서버

## 테스트 환경 구성
- Windows  공통설정
	- 방화벽 Off
	- 두 호스트 간 Ping
	- C:\Wavve\Config.ps1 실행
		- 리모트 연결을 활성화
	- 시스템 환경변수로 아래 변수를 추가 
		- VAULT_ADDR : http://13.209.40.188:8200
		- VAULT_TOKEN :  vault token create -policy=rotate-windows -period=76800h
	- Vault UI 에 Server 의 Administrator Cred 를 아래 폼으로 입력
		- Server
			- Path : systemcred/windows/172.31.1.184/Administrator_creds
			- Key : Administrator
			- Vaule : lE8fMoJ05D2oqAr499D43FTBWszjDaeWMsm7
- Windows Server
	- C:\Wavve\server\renewPassServer.ps1 파일 붙여넣기 
- Windows Client
	- C:\Wavve\client\RenewPassClient.bat 파일 실행
