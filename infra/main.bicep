targetScope = 'subscription'

@minLength(1)
@maxLength(12)
@description('Name of the project that can be used as part of naming resource convention')
param projectName string

@minLength(1)
@maxLength(8)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Id of the user or app to assign application roles')
param principalId string

@minLength(1)
@description('Name of the web app service that should match the name in the azure.yaml file')
param webAppServiceName string

param webAppExists bool

@secure()
param webAppConfig object

// Tags that should be applied to all resources.
//
// Note that 'azd-service-name' tags should be applied separately to service host resources.
// Example usage:
//   tags: union(tags, { 'azd-service-name': <service name in azure.yaml> })
var tags = {
  'azd-env-name': environmentName
}

// Load abbreviations to be used when naming resources
// See: https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations
var abbrs = loadJsonContent('./abbreviations.json')

// Generate a unique token to be used in naming resources
var resourceToken = take(toLower(uniqueString(subscription().id, environmentName, location, projectName)), 5)

// Functions for building resource names based on a naming convention
// See: https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming
func buildResourceGroupName(abbr string, projName string, envName string) string => toLower(join([ abbr, projName, envName ], '-'))

func buildProjectResourceName(abbr string, projName string, envName string, token string, useDelimiter bool) string => toLower(join([ abbr, useDelimiter ? projName : replace(projName, '-', ''), envName, token ], useDelimiter ? '-' : ''))

func buildServiceResourceName(abbr string, projName string, svcName string, envName string, token string, useDelimiter bool) string => toLower(join([ abbr, useDelimiter ? projName : replace(projName, '-', ''), useDelimiter ? svcName : replace(svcName, '-', ''), envName, token ], useDelimiter ? '-' : ''))

// Functions used for parsing and coalescing string values
func stringOrDefault(value string, default string) string => empty(value) ? default : value

func intOrDefault(value string, default int) int => empty(value) ? default : int(value)

func boolOrDefault(value string, default bool) bool => empty(value) ? default : bool(value)

resource resourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: buildResourceGroupName(abbrs.resourcesResourceGroups, projectName, environmentName)
  location: location
  tags: tags
}

module logAnalyticsWorkspace './insights/log-analytics-workspace.bicep' = {
  name: 'logAnalyticsWorkspace'
  scope: resourceGroup
  params: {
    name: buildProjectResourceName(abbrs.operationalInsightsWorkspaces, projectName, environmentName, resourceToken, true)
    location: location
    tags: tags
  }
}

module appInsights './insights/application-insights.bicep' = {
  name: 'appInsights'
  scope: resourceGroup
  params: {
    name: buildProjectResourceName(abbrs.insightsComponents, projectName, environmentName, resourceToken, true)
    location: location
    tags: tags
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
  }
}

module dashboard './insights/dashboard-web.bicep' = {
  name: 'dashboard'
  scope: resourceGroup
  params: {
    name: buildProjectResourceName(abbrs.portalDashboards, projectName, environmentName, resourceToken, true)
    location: location
    tags: tags
    applicationInsightsName: appInsights.outputs.name
  }
}

module keyVault './key-vault/key-vault.bicep' = {
  name: 'keyVault'
  scope: resourceGroup
  params: {
    name: buildProjectResourceName(abbrs.keyVaultVaults, projectName, environmentName, resourceToken, true)
    location: location
    tags: tags
    principalId: principalId
  }
}

module containerRegistry './containers/container-registry.bicep' = {
  name: 'containerRegistry'
  scope: resourceGroup
  params: {
    name: buildProjectResourceName(abbrs.containerRegistryRegistries, projectName, environmentName, resourceToken, false)
    location: location
    tags: tags
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
  }
}

module containerAppEnvironment './containers/container-app-environment.bicep' = {
  name: 'containerAppEnvironment'
  scope: resourceGroup
  params: {
    name: buildProjectResourceName(abbrs.appManagedEnvironments, projectName, environmentName, resourceToken, true)
    location: location
    tags: tags
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.outputs.name
    applicationInsightsName: appInsights.outputs.name
  }
}

// We need to compute the origin hostname for the web app - if a custom domain name is used, then we can use that, otherwise we need to use the default container app hostname
var webAppServiceContainerAppName = buildServiceResourceName(abbrs.appContainerApps, projectName, webAppServiceName, environmentName, resourceToken, true)

var webAppServiceCustomDomainName = stringOrDefault(webAppConfig.infraSettings.customDomainName, '')
var webAppServiceCustomDomainCertificateId = stringOrDefault(webAppConfig.infraSettings.customDomainCertificateId, '')

var webAppServiceHostName = !empty(webAppServiceCustomDomainName) && !empty(webAppServiceCustomDomainCertificateId) ? webAppServiceCustomDomainName : '${webAppServiceContainerAppName}.${containerAppEnvironment.outputs.defaultDomain}'

var webAppServiceUri = 'https://${webAppServiceHostName}'

var webAppTargetPort = 3000

var buildId = uniqueString(resourceGroup.id, deployment().name)

var nodeEnv = 'production'

module webAppCdn './cdn/cdn.bicep' = {
  name: '${webAppServiceName}-cdn'
  scope: resourceGroup
  params: {
    profileName: buildServiceResourceName(abbrs.cdnProfiles, projectName, webAppServiceName, environmentName, resourceToken, true)
    endpointName: buildServiceResourceName(abbrs.cdnProfilesEndpoints, projectName, webAppServiceName, environmentName, resourceToken, true)
    location: location
    tags: tags
    originHostName: webAppServiceHostName
  }
}

module webAppServiceIdentity './security/user-assigned-identity.bicep' = {
  name: '${webAppServiceName}-identity'
  scope: resourceGroup
  params: {
    name: buildServiceResourceName(abbrs.managedIdentityUserAssignedIdentities, projectName, webAppServiceName, environmentName, resourceToken, true)
    location: location
    tags: tags
  }
}

module webApp './web-app.bicep' = {
  name: webAppServiceName
  scope: resourceGroup
  params: {
    name: webAppServiceContainerAppName
    location: location
    tags: union(tags, {'azd-service-name':  webAppServiceName })
    containerAppEnvironmentName: containerAppEnvironment.outputs.name
    containerRegistryName: containerRegistry.outputs.name
    identityName: webAppServiceIdentity.outputs.name
    exists: webAppExists
    appConfig: webAppConfig
    customDomainName: webAppServiceCustomDomainName
    customDomainCertificateId: webAppServiceCustomDomainCertificateId
    env: [
      {
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: appInsights.outputs.connectionString
      }
      {
        name: 'BASE_URL'
        value: webAppServiceUri
      }
      {
        name: 'BUILD_ID'
        value: buildId
      }
      {
        name: 'CDN_URL'
        value: webAppCdn.outputs.endpointUri
      }
      {
        name: 'NODE_ENV'
        value: nodeEnv
      }
      {
        name: 'PORT'
        value: '${webAppTargetPort}'
      }
    ]
    targetPort: webAppTargetPort
  }
}

// azd outputs
output AZURE_LOCATION string = location
output AZURE_RESOURCE_GROUP string = resourceGroup.name
output AZURE_TENANT_ID string = tenant().tenantId

// Container outputs
output AZURE_CONTAINER_DOMAIN_VERIFICATION_CODE string = containerAppEnvironment.outputs.domainVerificationCode
output AZURE_CONTAINER_ENVIRONMENT_NAME string = containerAppEnvironment.outputs.name
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.name
output AZURE_CONTAINER_STATIC_IP string = containerAppEnvironment.outputs.staticIp

// Key vault outputs
output AZURE_KEY_VAULT_ENDPOINT string = keyVault.outputs.endpoint
output AZURE_KEY_VAULT_NAME string = keyVault.outputs.name

// Web app outputs
// Include anything here that wouldn't already be present in the local .env file
output APPLICATIONINSIGHTS_CONNECTION_STRING string = appInsights.outputs.connectionString
output BASE_URL string = webAppServiceUri
output BUILD_ID string = buildId
output CDN_URL string = webAppCdn.outputs.endpointUri
output NODE_ENV string = nodeEnv
output PORT int = webAppTargetPort
output SERVICE_WEB_APP_ENDPOINTS string[] = [webAppServiceUri]
output SERVICE_WEB_APP_FQDN string = webApp.outputs.fqdn
