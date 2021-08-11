param(
    [string]$NETWORKING_PREFIX, 
    [string]$BUILD_ENV, 
    [string]$RESOURCE_GROUP, 
    [string]$PREFIX,
    [string]$GITHUB_REF)

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

$adminPassword = [guid]::NewGuid().ToString("N").Substring(0, 7).ToUpper() + "!" + [guid]::NewGuid().ToString("N").Substring(0, 7).ToLower()

$rgName = "$RESOURCE_GROUP-$BUILD_ENV"
az deployment group create --name $deploymentName --resource-group $rgName --template-file Deployment/deploy.bicep --parameters `
    location=$location `
    prefix=$PREFIX `
    environment=$BUILD_ENV `
    branch=$GITHUB_REF `
    subnetId=$subnetId `
    adminPassword=$adminPassword