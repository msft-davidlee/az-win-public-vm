param prefix string
param environment string
param branch string
param location string
param subnetId string
@secure()
param adminPassword string

var stackName = '${prefix}${environment}'
var tags = {
  'stack-name': stackName
  'environment': environment
  'branch': branch
}

resource publicip 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: stackName
  tags: tags
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: stackName
    }
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: stackName
  tags: tags
  location: location
  properties: {
    ipConfigurations: [
      {
        name: stackName
        properties: {
          primary: true
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicip.id
          }
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2021-04-01' = {
  name: stackName
  location: location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2ms'
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter-Core-smalldisk'
        version: 'latest'
      }
      osDisk: {
        name: stackName
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    osProfile: {
      computerName: stackName
      adminUsername: stackName
      adminPassword: adminPassword
    }
  }
}

resource antimalware 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = {
  parent: vm
  name: 'Antimalware'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Security'
    type: 'IaaSAntimalware'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      AntimalwareEnabled: true
      RealtimeProtectionEnabled: true
      ScheduledScanSettings: {
        isEnabled: true
        scanType: 'Quick'
        day: 7
        time: '120'
      }
    }
  }
}

resource customscriptext 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = {
  parent: vm
  name: 'CustomScriptExtension'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      commandToExecute: loadTextContent('Custom.cmd')
    }
  }
}
