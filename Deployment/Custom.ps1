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
}

Set-Content -Path "C:\Users\$Username\.ssh\authorized_keys" -Value (Get-Content $PubKeyFile) -Force
Set-Content -Path "C:\ProgramData\ssh\authorized_keys" -Value (Get-Content $PubKeyFile) -Force