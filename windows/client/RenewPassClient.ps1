Clear-Host

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Ignore SSL for Call Rest API
if (-not("dummy" -as [type])) {
    add-type -TypeDefinition @"
using System;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;

public static class Dummy {
    public static bool ReturnTrue(object sender,
        X509Certificate certificate,
        X509Chain chain,
        SslPolicyErrors sslPolicyErrors) { return true; }

    public static RemoteCertificateValidationCallback GetDelegate() {
        return new RemoteCertificateValidationCallback(Dummy.ReturnTrue);
    }
}
"@
}

[System.Net.ServicePointManager]::ServerCertificateValidationCallback = [dummy]::GetDelegate()



$ErrorActionPreference = 'Continue'
$VerbosePreference = 'Continue' 
$savedPath = "C:\Wavve\windows\client"


###############################################################
# Functions
###############################################################
function addNewUser {
    param($server, $user, $group)

    $status = Get-WmiObject win32_pingStatus -Filter "address='${server}'" | Select-Object StatusCode
    if($status.statuscode) {
        return 0
    }

    Write-Host "Ping test passed - ${server}"

    $cred = getUserCred -server $server -user "Administrator"
    if($cred -eq ""){
        return 0
    }

    $password = generatePassword -server $server -user $user
    if($password -eq ""){
        return 0
    } 
    
    Write-Host "New Password generated - ${password}"
 
    $securedpass = ConvertTo-SecureString $password -AsPlainText -Force
     
    $result = Invoke-Command -ComputerName $server -ArgumentList $user, $securedpass, $group  -Credential $cred  -ScriptBlock {
        $USERNAME = $args[0]
        $PASSWORD = $args[1]
        $GROUPNAME = $args[2]
        $ObjLocalUser = $null
        
        $ObjLocalUser = Get-LocalUser $USERNAME -ErrorAction SilentlyContinue

        if (!$ObjLocalUser) {

            New-LocalUser -Name "$USERNAME" -Password $PASSWORD -FullName "$USERNAME" -Description "Test user" 
            Write-Host "You have successfully created a new user - ${USERNAME}"

            Add-LocalGroupMember -Group $GROUPNAME -Member $USERNAME
            if($?) {
                Write-Host "The user you created was added to an existing group - ${GROUPNAME}"

                $taskName = "ChangePassword";
                $task = Get-ScheduledTask | Where-Object { $_.TaskName -eq $taskName } | Select-Object -First 1
                if ($null -eq $task) {
                    # Register Schedule
                    $action = New-ScheduledTaskAction -Execute 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -Argument '-ExecutionPolicy Unrestricted -File "C:\Wavve\windows\server\renewPassServer.ps1"'
                    $trigger = New-ScheduledTaskTrigger -AtLogOn -User ${USERNAME}
                    $principal = New-ScheduledTaskPrincipal -UserId ${USERNAME} -RunLevel Highest
                    Register-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -TaskName $taskName -Description "Change Password"
                    if($?) {
                        Write-Host "The ChangePassword schedule has been registered"
                        return 1
                    }
                }
            }
        }

        return 0
    } 

    if($result -eq 0) {
        return 0
    }
    
    return 1
}

function changePassword {
    param($server, $user)

    $status = Get-WmiObject win32_pingStatus -Filter "address='$($server)'" | Select-Object StatusCode
    if($status.statuscode) {  
        return 0
    }

    Write-Host "Ping test passed - ${server}"

    $cred = getUserCred -server $server -user "Administrator"
    if($cred -eq ""){ 
        return 0
    }

    $password = generatePassword -server $server -user $user
    if($password -eq ""){ 
        return 0
    }
    
    Write-Host "New Password generated - ${password}"

    $result = Invoke-Command -ComputerName $server -ArgumentList $user, $password -Credential $cred  -ScriptBlock {
        $USERNAME = $args[0]
        $PASSWORD = $args[1] 
        $ObjLocalUser = $null

        $sessionID = ((quser  | Where-Object { $_ -match $USERNAME }) -split ' +')[2]
        if ($sessionID) {
            Logoff $sessionID
        }
        
        $ObjLocalUser = Get-LocalUser $USERNAME -ErrorAction SilentlyContinue 

        if ($ObjLocalUser) {
            $app = 'net user '+${USERNAME}+ ' '+${PASSWORD}
            Invoke-Expression -Command:$app 
            if($?) {
                Write-Host "The password for the existing account has been changed - ${USERNAME}"

                $taskName = "ChangePassword";
                $task = Get-ScheduledTask | Where-Object { $_.TaskName -eq $taskName } | Select-Object -First 1
                if ($null -eq $task) {
                    # Register Schedule
                    $action = New-ScheduledTaskAction -Execute 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -Argument '-ExecutionPolicy Unrestricted -File "C:\Wavve\windows\server\renewPassServer.ps1"'
                    $trigger = New-ScheduledTaskTrigger -AtLogOn -User ${USERNAME}
                    $principal = New-ScheduledTaskPrincipal -UserId ${USERNAME} -RunLevel Highest
                    Register-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -TaskName $taskName -Description "Change Password"
                    if($?) {
                        Write-Host "The ChangePassword schedule has been registered"
                        return 1
                    }
                }
            }


        }
    }

    if($result) {
        return 1
    } 

    return 0
}



function getUserCred {
    param($server,$user)
 
    $adminPassword = getPassword -server "${server}" -user "${user}"

    if($adminPassword)
    { 
      $passwd = Convertto-Securestring -AsPlainText -Force -String $adminPassword
      $cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist "administrator",$passwd
      return $cred
    } 

    return ""
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
# Main Dialog
###############################################################
$dlg = New-Object System.Windows.Forms.Form
$dlg.Text = "Test Server"
$dlg.Height = 700
$dlg.Width = 700
$dlg.StartPosition = "CenterScreen"
$icon = [System.Drawing.Icon]::ExtractAssociatedIcon("C:\Program Files\Windows Mail\wabmig.exe")
$dlg.Icon = $icon
$image = [System.Drawing.Image]::FromFile("$($savedPath)\screen.png")
$dlg.BackgroundImage = $image
$dlg.BackgroundImageLayout = "Center"
$dlg.Add_KeyDown{
  if($_.keycode -eq "Escape") {
    $dlg.Close()
  }
}


###############################################################
# Title Label 
###############################################################
$lbTitle = New-Object System.Windows.Forms.Label
$lbTitle.Font = New-Object System.Drawing.Font("Arial",18,[System.Drawing.FontStyle]::Bold)
$lbTitle.Location = New-Object System.Drawing.Size(90,100)
$lbTitle.Size = New-Object System.Drawing.Size(500,30)
$lbTitle.Text = "Windows Server Account Management"
$lbTitle.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter


###############################################################
#  Target Server Selection
###############################################################
$lbInput = New-Object System.Windows.Forms.Label 
$lbInput.Location = New-Object System.Drawing.Size(200,140)
$lbInput.Size = New-Object System.Drawing.Size(95,22)
$lbInput.Text = "Server Name"
$lbInput.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter 

$serverList = Get-Content  "C:\Powershell\serverList.txt"
$servers = $serverList.Split(" ")


$cmbServers = New-Object System.Windows.Forms.ComboBox
$cmbServers.Location = New-Object System.Drawing.Size(300,140)
$cmbServers.Size = New-Object System.Drawing.Size(200,30)
$cmbServers.Text = "Choose Server" 
foreach($server in $servers){
  $cmbServers.Items.Add($server)
}

$cmbServers.Add_SelectedIndexChanged({
    if($cmbServers.SelectedItem -gt 0) {  
        $server = $cmbServers.SelectedItem
        $cred = getUserCred -server $server -user "Administrator"
        if($cred -eq ""){
             Write-Error "Failed to get admin_cred"
            return 0
        }

        $groups = Invoke-Command  -ComputerName $cmbServers.SelectedItem -Credential $cred -ScriptBlock { 
            $localGroups = net localgroup
            return $localGroups
        }

        $cmbGroups.Items.Clear()
        foreach($group in $groups) { 
            if($group.StartsWith("*")){
                $group = $group.Replace("*","")
                $cmbGroups.Items.Add($group)       
            }
        } 
    }
})

###############################################################
#  Target Group Selection
############################################################### 
$lbGroup = New-Object System.Windows.Forms.Label 
$lbGroup.Location = New-Object System.Drawing.Size(200,170)
$lbGroup.Size = New-Object System.Drawing.Size(95,22)
$lbGroup.Text = "Group Name"
$lbGroup.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter

 
$cmbGroups = New-Object System.Windows.Forms.ComboBox
$cmbGroups.Location = New-Object System.Drawing.Size(300,170)
$cmbGroups.Size = New-Object System.Drawing.Size(200,30)
$cmbGroups.Text = "Choose Group"
$cmbGroups.Add_SelectedIndexChanged({
    if($cmbGroups.SelectedItem -gt 0) { 
        $group = $cmbGroups.SelectedItem 
        $server = $cmbServers.SelectedItem
 
        $cred = getUserCred -server $server -user "Administrator"
        if($cred -eq ""){
             Write-Error "Failed to get admin_cred"
            return 0
        }

        $users = Invoke-Command  -ComputerName $server -Credential $cred -ArgumentList $group -ScriptBlock { 
            $GROUPNAME = $args[0]
            $USERS = Get-LocalGroupMember -Group $GROUPNAME 
            return $USERS
        }

        $cmbUsers.Items.Clear()
        foreach($user in $users) { 
            $userInfo =$user -split '\\' 
            $cmbUsers.Items.Add($userInfo[1])
        } 
    }
})


###############################################################
#  Target User Selection
###############################################################
$lbUser = New-Object System.Windows.Forms.Label 
$lbUser.Location = New-Object System.Drawing.Size(200,210)
$lbUser.Size = New-Object System.Drawing.Size(95,22)
$lbUser.Text = "Exist User"
$lbUser.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter

 
$cmbUsers = New-Object System.Windows.Forms.ComboBox
$cmbUsers.Location = New-Object System.Drawing.Size(300,210)
$cmbUsers.Size = New-Object System.Drawing.Size(200,30)
$cmbUsers.Text = "Choose User" 


$lbNewUser = New-Object System.Windows.Forms.Label 
$lbNewUser.Location = New-Object System.Drawing.Size(200,240)
$lbNewUser.Size = New-Object System.Drawing.Size(95,22)
$lbNewUser.Text = "New User"
$lbNewUser.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter

$txtUser = New-Object System.Windows.Forms.TextBox
$txtUser.Location = New-Object System.Drawing.Size(300,240)
$txtUser.Size = New-Object System.Drawing.Size(200,30)  

 $dlg.Controls.Add($lbNewUser)


###############################################################
# Log Folder Selection 
###############################################################
$lbFolder = New-Object System.Windows.Forms.Label 
$lbFolder.Location = New-Object System.Drawing.Size(200,300)
$lbFolder.Size = New-Object System.Drawing.Size(300,30)
$lbFolder.Text = "Select Log Folder"
$lbFolder.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter

$txtLogFolder = New-Object System.Windows.Forms.TextBox
$txtLogFolder.Location = New-Object System.Drawing.Size(200,335)
$txtLogFolder.Size = New-Object System.Drawing.Size(300,30) 


$txtLogFolder.Add_DoubleClick({
    $forderName = New-Object System.Windows.Forms.FolderBrowserDialog 
    $rtn = $forderName.ShowDialog() 
    Write-Host "FolderName Return : $($rtn)"
    if($rtn -eq "OK") {
        $savedPath = $forderName.SelectedPath
        $txtLogFolder.Text = $savedPath
         Write-Host "Saved Path : $($savedPath)"
    } 
})


###############################################################
# Operations
###############################################################
$cmbFunctions = New-Object System.Windows.Forms.ComboBox
$cmbFunctions.Location = New-Object System.Drawing.Size(250,365)
$cmbFunctions.Size = New-Object System.Drawing.Size(200,25)
$cmbFunctions.Text = "Select Function"
$cmbList = @(
    "addNewUser",
    "changePassword"
)
foreach($item in $cmbList){
  $cmbFunctions.Items.Add($item)
}


$btnOk = New-Object System.Windows.Forms.Button
$btnOk.Location = New-Object System.Drawing.Size(250,390)
$btnOk.Size = New-Object System.Drawing.Size(100,25) 
$btnOk.Text = "OK"
$btnOk.Add_Click({    
    switch($cmbFunctions.SelectedItem) {
        "addNewUser" {
            $server = $cmbServers.SelectedItem 
            $user = $txtUser.Text
            $group = $cmbGroups.SelectedItem 
    
            if($server  -and $user -and  $group){
                addNewUser -server  $server -user $user -group $group
            }
        }
        "changePassword" {
            $server = $cmbServers.SelectedItem 
            $user = $cmbUsers.SelectedItem
            $group = $cmbGroups.SelectedItem 
    
            if($server -and $user -and  $group){ 
                changePassword -server $server -user $user
            }
        }
    } 
})

$btnClose = New-Object System.Windows.Forms.Button
$btnClose.Location = New-Object System.Drawing.Size(350,390)
$btnClose.Size = New-Object System.Drawing.Size(100,25) 
$btnClose.Text = "Close"
$btnClose.Add_Click({
    $dlg.Close()
})
 

###############################################################
# Add items to dialog
###############################################################
$dlg.Controls.Add($lbTitle)
$dlg.Controls.Add($lbInput)
$dlg.Controls.Add($lbFolder) 
$dlg.Controls.Add($txtLogFolder) 
$dlg.Controls.Add($btnOk)
$dlg.Controls.Add($btnClose)
$dlg.Controls.Add($cmbFunctions)
$dlg.Controls.Add($cmbServers)
$dlg.Controls.Add($lbUser)
$dlg.Controls.Add($cmbUsers)
$dlg.Controls.Add($txtUser)
$dlg.Controls.Add($lbGroup)
$dlg.Controls.Add($cmbGroups)
$dlg.ShowDialog()
