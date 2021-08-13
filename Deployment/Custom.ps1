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
    Set-Service -Name sshd -StartupType 'Automatic'
    Start-Service sshd
    New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
    Stop-Service sshd

    Copy-Item -Path $PubKeyFile -Destination "C:\ProgramData\ssh\administrators_authorized_keys" -Force

    $content = Get-Content "C:\ProgramData\ssh\sshd_config"
    $content = $content.Replace("#PubkeyAuthentication yes", "PubkeyAuthentication yes")
    $content = $content.Replace("#PasswordAuthentication yes", "PasswordAuthentication no")
    $content = $content.Replace("#StrictModes yes", "StrictModes no")

    Set-Content -Path "C:\ProgramData\ssh\sshd_config" -Value $content

    Start-Service sshd
}
else {
    Write-Host "SSH already installed"
}