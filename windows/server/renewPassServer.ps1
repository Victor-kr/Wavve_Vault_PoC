Clear-Host

# Ignore SSL 
add-type @"
   using System.Net;
   using System.Security.Cryptography.X509Certificates;
   public class TrustAllCertsPolicy : ICertificatePolicy {
      public bool CheckValidationResult(
      ServicePoint srvPoint, X509Certificate certificate,
      WebRequest request, int certificateProblem) {
      return true;
   }
}
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy


$ErrorActionPreference = "Continue"  
$VerbosePreference = 'Continue' 

###############################################################
# Functions
###############################################################

 function getLoggedInUser {
     param($server) 

     $SessionList = quser /Server:"${server}" 2>$null
     if ($SessionList) {
         $UserInfos = foreach ($Session in ($SessionList | select -Skip 1)) {
             $Session = $Session.ToString().trim() -replace '\s+', ' ' -replace '>', ''
             if ($Session.Split(' ')[3] -eq 'Active') {
                 [PSCustomObject]@{
                     ComputerName = $Computer
                     UserName     = $session.Split(' ')[0]
                     SessionName  = $session.Split(' ')[1]
                     SessionID    = $Session.Split(' ')[2]
                     SessionState = $Session.Split(' ')[3]
                     IdleTime     = $Session.Split(' ')[4]
                     LogonTime    = $session.Split(' ')[5, 6, 7] -as [string] -as [datetime]
                 }
             } else {
                 [PSCustomObject]@{
                     ComputerName = $Computer
                     UserName     = $session.Split(' ')[0]
                     SessionName  = $null
                     SessionID    = $Session.Split(' ')[1]
                     SessionState = 'Disconnected'
                     IdleTime     = $Session.Split(' ')[3]
                     LogonTime    = $session.Split(' ')[4, 5, 6] -as [string] -as [datetime]
                 }
             }
         }

         return $UserInfos
    }

    return $null
}

function getPassword {
    param($server, $user)

    $VAULT_ADDR = $env:VAULT_ADDR 
 
    # Get pwadmin user token
    $Body = @{
       password = "password" 
    } | ConvertTo-Json

    $Params = @{
         Method = "POST"
         Headers = $Header
         Uri = "${VAULT_ADDR}/v1/auth/userpass/login/pwadmin"
         Body = $Body
         ContentType = "application/json"
    }

    $Result = Invoke-RestMethod @Params

    if(-Not $?)
    {
      return ""
    }

    # Get userpassword
    $VAULT_TOKEN = $Result.auth.client_token

    $Header = @{
        "X-Vault-Token" = "${VAULT_TOKEN}"
    }

    $Params = @{
         Method = "GET"
         Headers = $Header
         Uri = "${VAULT_ADDR}/v1/systemcreds/data/windows/${server}/${user}_creds" 
    }

    $Result = Invoke-RestMethod @Params

    if(-Not $?)
    {
      return ""
    }

    $Password = $Result.data.data.${user}

    return $Password
}


function getUserCred {
    param($server,$user)
 
    $adminPassword = getPassword -server "${server}" -user "${user}"

    if($adminPassword)
    { 
      $passwd = Convertto-Securestring -AsPlainText -Force -String $adminPassword
      $cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist "Administrator",$passwd
      return $cred
    } 

    return ""
}

function generatePassword {
    param($server, $user)

    $VAULT_ADDR = $env:VAULT_ADDR
    $VAULT_TOKEN = $env:VAULT_TOKEN
 
    # Vault 서비스 인스턴스의 토큰 갱신,  토큰의 만료 및 자동 해지가 방지 
    $Header = @{
        "X-Vault-Token" = ${VAULT_TOKEN}
    }

    $Params = @{
         Method = "POST"
         Headers = $Header
         Uri = "${VAULT_ADDR}/v1/auth/token/renew-self" 
    }

    $Result = Invoke-RestMethod @Params
    if(-Not $?)
    {
      return ""
    }

    # 신규 Password 생성
    $Body = @{
       length = 36
       symbols = 0
    } | ConvertTo-Json 

    $Params = @{
         Method = "POST"
         Headers = $Header
         Uri = "${VAULT_ADDR}/v1/gen/password"
         Body = $Body
         ContentType = "application/json"
    }

    $Result = Invoke-RestMethod @Params

    if(-Not $?)
    {
      return ""
    } 

    # Vault 에 신규 Password 저장
    $NewPass = $Result.data.value
 
    $Body="{ `"options`": { `"max_versions`": 12 }, `"data`": { `"$user`": `"$NEWPASS`" } }"

    $Params = @{
         Method = "POST"
         Headers = $Header
         Uri = "${VAULT_ADDR}/v1/systemcreds/data/windows/${server}/${user}_creds"
         Body = $Body
         ContentType = "application/json"
    }

    $Results = Invoke-RestMethod @Params

    if(-Not $?)
    {
      return ""
    } 
     
    return $NewPass
}

 

###############################################################
# Main
###############################################################

$user = $env:USERNAME
$server = Get-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $(Get-NetConnectionProfile | Select-Object -ExpandProperty InterfaceIndex) | Select-Object -ExpandProperty IPAddress

if ("${user}" -eq "Administrator") {
    exit
}

$userInfos = getLoggedInUser  -server $server 
if($userInfos -eq $null) {
    EXIT
}

foreach ($userInfo in $userInfos) {
   if(($userInfo.UserName -eq $user) -and ($userInfo.SessionState -ne "Disconnected")){

        Write-Verbose $userInfo.UserName
        Write-Verbose $userInfo.SessionState
        Write-Verbose ""

        $adminCred = getUserCred -server $server -user "Administrator"
        if($adminCred -eq ""){
             Write-Error "Failed to get admin_cred"
            EXIT
        } 

        $newpass = generatePassword -server "${server}" -user "${user}"
        if($newpass -eq ""){ 
	        EXIT
        }

        Write-Verbose "New Password : ${newpass}"

        $Result = Invoke-Command -ComputerName $server -ArgumentList $user, $newpass -Credential $adminCred  -ScriptBlock {
            $USERNAME = $args[0]
            $PASSWORD = $args[1] 
            $ObjLocalUser = $null

            $app = 'net user '+$USERNAME+ ' '+$PASSWORD
            Invoke-Expression -Command:$app  
            if(-Not $?)
            {
                EXIT
            }
        }
    }
}
