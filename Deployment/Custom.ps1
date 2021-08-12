param([string]$PubKeyFile, [string]$Username)

$sshWinPath = "C:\Windows\system32\config\systemprofile\AppData\Local\Temp\"
if (!(Test-Path $sshWinPath)) {
    New-Item -ItemType Directory -Force -Path $sshWinPath
}

try {
    # https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse
    $state = (Get-WindowsCapability -Name OpenSSH.Server~~~~0.0.1.0 -Online).State    
}
catch {
    # May get this error which we should retry: Ensure that the path to the temporary folder exists and that you have Read/Write permissions on the folder.
    # C:\Windows\system32\config\systemprofile\AppData\Local\Temp\ could not be created.
    Write-Host "An error occured while detecting SSH. Trying again."
    $state = (Get-WindowsCapability -Name OpenSSH.Server~~~~0.0.1.0 -Online).State
}

if ($state -ne "Installed") {
    Write-Host "Installing SSH"
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
    Start-Service sshd
    Set-Service -Name sshd -StartupType 'Automatic'
    New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
}
else {
    Write-Host "SSH already installed"
}

if (!(Test-Path "C:\Users\$Username\.ssh")) {
    New-Item -Path "C:\Users\$Username\.ssh" -ItemType Directory -Force    
    Copy-Item -Path $PubKeyFile -Destination "C:\Users\$Username\.ssh\authorized_keys" -Force
    #Set-Content -Path "C:\Users\$Username\.ssh\authorized_keys" -Value (Get-Content $PubKeyFile) -Force
    #Set-Content -Path "C:\ProgramData\ssh\administrators_authorized_keys" -Value (Get-Content $PubKeyFile) -Force

    $content = Get-Content "C:\ProgramData\ssh\sshd_config"
    $content = $content.Replace("#PasswordAuthentication yes","PasswordAuthentication no")
    $content = $content.Replace("Match Group administrators","#Match Group administrators")
    $content = $content.Replace("       AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys","#       AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys")

    Set-Content -Path "C:\ProgramData\ssh\sshd_config" -Value $content

    $acl = Get-Acl "C:\Users\$Username\.ssh\authorized_keys"
    $acl.SetAccessRuleProtection($true, $false)
    $administratorsRule = New-Object system.security.accesscontrol.filesystemaccessrule("Administrators", "FullControl", "Allow")
    $systemRule = New-Object system.security.accesscontrol.filesystemaccessrule("SYSTEM", "FullControl", "Allow")
    $acl.SetAccessRule($administratorsRule)
    $acl.SetAccessRule($systemRule)
    $acl | Set-Acl

    Restart-Service sshd
}