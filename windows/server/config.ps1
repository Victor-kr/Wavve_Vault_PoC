Clear-Host 

###############################################################
# Remote Settings
###############################################################
# Remote 설정 초기화
Get-PSSessionConfiguration -Name Microsoft.PowerShell | Unregister-PSSessionConfiguration

# Remote 연결 허용
Enable-PSRemoting -Force
Set-NetFirewallRule -Name "WINRM-HTTP-In-TCP-PUBLIC" -RemoteAddress Any

# WinRM 서비스 항상 실행되도록 설정
Set-Service WinRM -ComputerName $(hostname) -startuptype Automatic

# 신뢰할수 있는 Host 등록 (IP, Domain 가능하며 * 라고 넣으면 모든 호스트) 
Set-Item WSMan:\localhost\Client\TrustedHosts  -Value "*" -Force
Get-Item WSMan:\localhost\Client\TrustedHosts 
