param name string
param location string = resourceGroup().location
param tags object = {}
param logAnalyticsWorkspaceName string
param applicationInsightsName string

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
    daprAIConnectionString: applicationInsights.properties.ConnectionString
  }
}

output id string = containerAppEnvironment.id
output name string = containerAppEnvironment.name
output defaultDomain string = containerAppEnvironment.properties.defaultDomain
output staticIp string = containerAppEnvironment.properties.staticIp
output domainVerificationCode string = containerAppEnvironment.properties.customDomainConfiguration.customDomainVerificationId
