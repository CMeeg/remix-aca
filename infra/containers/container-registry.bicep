param name string
param location string = resourceGroup().location
param tags object = {}
param logAnalyticsWorkspaceId string

// This is enabled by default because of an error when running `azd deploy` "Cannot perform credential operations for {containerId} as admin user is disabled" - would prefer to disable though
param adminUserEnabled bool = true
param anonymousPullEnabled bool = false
param dataEndpointEnabled bool = false
param encryption object = {
  status: 'disabled'
}
param networkRuleBypassOptions string = 'AzureServices'
param publicNetworkAccess string = 'Enabled'
param sku object = {
  name: 'Basic'
}
param zoneRedundancy string = 'Disabled'

// 2022-02-01-preview needed for anonymousPullEnabled
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' = {
  name: name
  location: location
  tags: tags
  #disable-next-line BCP035
  sku: sku
  properties: {
    adminUserEnabled: adminUserEnabled
    anonymousPullEnabled: anonymousPullEnabled
    dataEndpointEnabled: dataEndpointEnabled
    encryption: encryption
    networkRuleBypassOptions: networkRuleBypassOptions
    publicNetworkAccess: publicNetworkAccess
    zoneRedundancy: zoneRedundancy
  }
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diagnostics'
  scope: containerRegistry
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'ContainerRegistryRepositoryEvents'
        enabled: true
      }
      {
        category: 'ContainerRegistryLoginEvents'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        timeGrain: 'PT1M'
      }
    ]
  }
}

output id string = containerRegistry.id
output name string = containerRegistry.name
output loginServer string = containerRegistry.properties.loginServer
