param(
    [string]$NETWORKING_PREFIX, 
    [string]$BUILD_ENV, 
    [string]$RESOURCE_GROUP, 
    [string]$PREFIX,
    [string]$GITHUB_REF,
    [string]$VM_PASSWORD,
    [string]$PUB_KEY_FILE)

$ErrorActionPreference = "Stop"

$deploymentName = "vmdeploy" + (Get-Date).ToString("yyyyMMddHHmmss")
$platformRes = (az resource list --tag stack-name=$NETWORKING_PREFIX | ConvertFrom-Json)
if (!$platformRes) {
    throw "Unable to find eligible Virtual Network resource!"
}
if ($platformRes.Length -eq 0) {
    throw "Unable to find 'ANY' eligible Virtual Network resource!"
}
$vnet = ($platformRes | Where-Object { $_.type -eq "Microsoft.Network/virtualNetworks" -and $_.name.Contains("-pri-") -and $_.resourceGroup.EndsWith("-$BUILD_ENV") })
if (!$vnet) {
    throw "Unable to find Virtual Network resource!"
}
$vnetRg = $vnet.resourceGroup
$vnetName = $vnet.name
$location = $vnet.location
$subnets = (az network vnet subnet list -g $vnetRg --vnet-name $vnetName | ConvertFrom-Json)
if (!$subnets) {
    throw "Unable to find eligible Subnets from Virtual Network $vnetName!"
}          
$subnetId = ($subnets | Where-Object { $_.name -eq "default" }).id
if (!$subnetId) {
    throw "Unable to find Subnet resource!"
}

$asgId = (az resource list --name 'ssh-asg' -g $vnetRg --query [].id | ConvertFrom-Json).ToString()

$folderName = "files"
$rgName = "$RESOURCE_GROUP-$BUILD_ENV"
$deployOutputText = (az deployment group create --name $deploymentName --resource-group $rgName --template-file Deployment/deploy.bicep --parameters `
        location=$location `
        prefix=$PREFIX `
        environment=$BUILD_ENV `
        branch=$GITHUB_REF `
        subnetId=$subnetId `
        adminPassword="$VM_PASSWORD" `
        folderName=$folderName `
        asgId=$asgId)

$deployOutput = $deployOutputText | ConvertFrom-Json
$StackName = $deployOutput.properties.outputs.stackName.value
$Username = $deployOutput.properties.outputs.username.value
$file = "Custom.ps1"

$keys = az storage account keys list -g $rgName -n $StackName | ConvertFrom-Json
if ($LastExitCode -ne 0) {
    throw "An error has occured with storage key lookup."
}
$key1 = $keys[0].value

az storage blob upload -f "Deployment\$file" -c $folderName -n $file --account-name $StackName --account-key $key1
if ($LastExitCode -ne 0) {
    throw "An error has occured."
}

az storage blob upload -f $PUB_KEY_FILE -c $folderName -n $PUB_KEY_FILE --account-name $StackName --account-key $key1
if ($LastExitCode -ne 0) {
    throw "An error has occured."
}

$pubKeyLocation = "https://$StackName.blob.core.windows.net/$folderName/$PUB_KEY_FILE"
$scriptLocation = "https://$StackName.blob.core.windows.net/$folderName/$file"

$settings = @{ "fileUris" = @($scriptLocation, $pubKeyLocation); } | ConvertTo-Json -Compress
$settings = $settings.Replace("""", "'")

$protectedSettings = @{"commandToExecute" = "powershell -ExecutionPolicy Unrestricted -File $file -Username $Username -PubKeyFile $PUB_KEY_FILE"; "storageAccountName" = $StackName; "storageAccountKey" = $key1 } | ConvertTo-Json -Compress
$protectedSettings = $protectedSettings.Replace("""", "'")

az vm extension set -n CustomScriptExtension --publisher Microsoft.Compute --vm-name $StackName --resource-group $rgName `
    --protected-settings $protectedSettings --settings $settings --force-update

if ($LastExitCode -ne 0) {
    throw "An error has occured."
}