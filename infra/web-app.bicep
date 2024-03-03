param name string
param location string = resourceGroup().location
param tags object = {}
param containerAppEnvironmentName string
param containerRegistryName string
param identityName string
param exists bool
@secure()
param appConfig object
param allowedOrigins array = []
param containerCpuCoreCount string = '0.5'
param containerMaxReplicas int = 1
param containerMemory string = '1.0Gi'
param containerMinReplicas int = 0
param containerName string = 'main'
param customDomainName string = ''
param customDomainCertificateId string = ''
param env array = []
param external bool = true
param ingressEnabled bool = true
param revisionMode string = 'Single'
param secrets array = []
param serviceBinds array = []
param serviceType string = ''
param targetPort int = 80

var appSettings = filter(array(appConfig.appSettings), i => i.name != '')

var appSecrets = map(filter(appSettings, i => i.?secret != null), i => {
  name: i.name
  value: i.value
  secretRef: i.?secretRef ?? take(replace(replace(toLower(i.name), '_', '-'), '.', '-'), 32)
})

var appEnv = map(filter(appSettings, i => i.?secret == null), i => {
  name: i.name
  value: i.value
})

resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2023-04-01-preview' existing = {
  name: containerAppEnvironmentName
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' existing = {
  name: containerRegistryName
}

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: identityName
}

resource acrPullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: containerRegistry
  name: guid(subscription().id, resourceGroup().id, identity.id, 'acrPullRole')
  properties: {
    roleDefinitionId:  subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
    principalType: 'ServicePrincipal'
    principalId: identity.properties.principalId
  }
}

resource existingApp 'Microsoft.App/containerApps@2023-05-01' existing = if (exists) {
  name: name
}

var imageName = exists ? existingApp.properties.template.containers[0].image : 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

module containerApp './containers/container-app.bicep' = {
  name: 'web-app-container-app'
  dependsOn: [ acrPullRole ]
  params: {
    name: name
    location: location
    tags: tags
    containerAppEnvironmentId: containerAppEnvironment.id
    containerRegistryName: containerRegistry.name
    userAssignedIdentityId: identity.id
    allowedOrigins: allowedOrigins
    containerCpuCoreCount: empty(appConfig.infraSettings.containerCpuCoreCount) ? containerCpuCoreCount : appConfig.infraSettings.containerCpuCoreCount
    containerMaxReplicas: empty(appConfig.infraSettings.containerMaxReplicas) ? containerMaxReplicas : int(appConfig.infraSettings.containerMaxReplicas)
    containerMemory: empty(appConfig.infraSettings.containerMemory) ? containerMemory : appConfig.infraSettings.containerMemory
    containerMinReplicas: empty(appConfig.infraSettings.containerMinReplicas) ? containerMinReplicas : int(appConfig.infraSettings.containerMinReplicas)
    containerName: containerName
    customDomainName: empty(appConfig.infraSettings.customDomainName) ? customDomainName : appConfig.infraSettings.customDomainName
    customDomainCertificateId: empty(appConfig.infraSettings.customDomainCertificateId) ? customDomainCertificateId : appConfig.infraSettings.customDomainCertificateId
    env: union(
      env,
      appEnv,
      map(appSecrets, secret => {
        name: secret.name
        secretRef: secret.secretRef
      })
    )
    external: external
    imageName: imageName
    ingressEnabled: ingressEnabled
    revisionMode: revisionMode
    secrets: union(
      secrets,
      map(appSecrets, secret => {
        name: secret.secretRef
        value: secret.value
      })
    )
    serviceBinds: serviceBinds
    serviceType: serviceType
    targetPort: targetPort
  }
}

output id string = containerApp.outputs.id
output name string = containerApp.outputs.name
output serviceBind object = containerApp.outputs.serviceBind
output fqdn string = containerApp.outputs.fqdn
output uri string = containerApp.outputs.uri
