param name string
param location string = resourceGroup().location
param tags object = {}
param containerAppEnvironmentId string
param containerRegistryName string
param userAssignedIdentityId string
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
param imageName string = ''
param ingressEnabled bool = true
param revisionMode string = 'Single'
param secrets array = []
param serviceBinds array = []
param serviceType string = ''
param targetPort int = 80

resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppEnvironmentId
    configuration: {
      activeRevisionsMode: revisionMode
      ingress: ingressEnabled ? {
        external: external
        targetPort: targetPort
        transport: 'auto'
        corsPolicy: {
          allowedOrigins: union([ 'https://portal.azure.com', 'https://ms.portal.azure.com' ], allowedOrigins)
        }
        customDomains: !empty(customDomainName) ? [
          {
            name: customDomainName
            certificateId: !empty(customDomainCertificateId) ? customDomainCertificateId : null
            bindingType: !empty(customDomainCertificateId) ? 'SniEnabled' : 'Disabled'
          }
        ] : null
      } : null
      dapr: { enabled: false }
      secrets: secrets
      service: !empty(serviceType) ? { type: serviceType } : null
      registries: [
        {
          server: '${containerRegistryName}.azurecr.io'
          identity: userAssignedIdentityId
        }
      ]
    }
    template: {
      serviceBinds: !empty(serviceBinds) ? serviceBinds : null
      containers: [
        {
          image: imageName
          name: containerName
          env: env
          resources: {
            cpu: json(containerCpuCoreCount)
            memory: containerMemory
          }
        }
      ]
      scale: {
        minReplicas: containerMinReplicas
        maxReplicas: containerMaxReplicas
      }
    }
  }
}

output id string = containerApp.id
output name string = containerApp.name
output serviceBind object = !empty(serviceType) ? { serviceId: containerApp.id, name: name } : {}
output fqdn string = ingressEnabled ? containerApp.properties.configuration.ingress.fqdn : ''
output uri string = ingressEnabled ? 'https://${containerApp.properties.configuration.ingress.fqdn}' : ''
