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
param webAppDefinition object

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

// This file is created by an azd `preprovision` hook - if you're seeing an error here and elsewhere because this file doesn't exist, run `.azd/scripts/create-infra-env-vars.ps1` directly or via `azd provision` to create the file
var envVars = loadJsonContent('./env-vars.json')

// Generate a unique token to be used in naming resources
var resourceToken = take(toLower(uniqueString(subscription().id, environmentName, location, projectName)), 4)

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

module monitoring './shared/monitoring.bicep' = {
  name: 'monitoring'
  scope: resourceGroup
  params: {
    logAnalyticsName: buildProjectResourceName(abbrs.operationalInsightsWorkspaces, projectName, environmentName, resourceToken, true)
    applicationInsightsName: buildProjectResourceName(abbrs.insightsComponents, projectName, environmentName, resourceToken, true)
    location: location
    tags: tags
  }
}

module dashboard './shared/dashboard-web.bicep' = {
  name: 'dashboard'
  scope: resourceGroup
  params: {
    name: buildProjectResourceName(abbrs.portalDashboards, projectName, environmentName, resourceToken, true)
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    location: location
    tags: tags
  }
}

module containerRegistry './shared/registry.bicep' = {
  name: 'registry'
  scope: resourceGroup
  params: {
    name: buildProjectResourceName(abbrs.containerRegistryRegistries, projectName, environmentName, resourceToken, false)
    location: location
    tags: tags
  }
}

module keyVault './shared/keyvault.bicep' = {
  name: 'keyvault'
  scope: resourceGroup
  params: {
    name: buildProjectResourceName(abbrs.keyVaultVaults, projectName, environmentName, resourceToken, true)
    location: location
    tags: tags
    principalId: principalId
  }
}

module containerAppEnvironment './shared/apps-env.bicep' = {
  name: 'apps-env'
  scope: resourceGroup
  params: {
    name: buildProjectResourceName(abbrs.appManagedEnvironments, projectName, environmentName, resourceToken, true)
    logAnalyticsWorkspaceName: monitoring.outputs.logAnalyticsWorkspaceName
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    location: location
    tags: tags
  }
}

// We need to compute the origin hostname for the web app - if a custom domain name is used, then we can use that, otherwise we need to use the default container app hostname
var webAppServiceContainerAppName = buildServiceResourceName(abbrs.appContainerApps, projectName, webAppServiceName, environmentName, resourceToken, true)

var webAppServiceCustomDomainName = stringOrDefault(webAppDefinition.config.customDomainName, '')

var webAppServiceHostName = !empty(webAppServiceCustomDomainName) ? webAppServiceCustomDomainName : '${webAppServiceContainerAppName}.${containerAppEnvironment.outputs.defaultDomain}'

var webAppServiceUri = 'https://${webAppServiceHostName}'

var buildId = uniqueString(resourceGroup.id, deployment().name)

module webApp './app/web-app.bicep' = {
  name: webAppServiceName
  scope: resourceGroup
  params: {
    name: webAppServiceContainerAppName
    location: location
    tags: union(tags, {'azd-service-name':  webAppServiceName })
    identityName: buildServiceResourceName(abbrs.managedIdentityUserAssignedIdentities, projectName, webAppServiceName, environmentName, resourceToken, true)
    containerAppsEnvironmentName: containerAppEnvironment.outputs.name
    containerRegistryName: containerRegistry.outputs.name
    exists: webAppExists
    appDefinition: union(webAppDefinition, {
      env: [
        {
          name: 'APP_ENV'
          value: environmentName
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: monitoring.outputs.applicationInsightsConnectionString
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
          name: 'MIN_LOG_LEVEL'
          value: stringOrDefault(envVars.MIN_LOG_LEVEL, '30')
        }
        {
          name: 'NODE_ENV'
          value: 'production'
        }
        {
          name: 'PROJECT_NAME'
          value: projectName
        }
      ]
    })
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
output SERVICE_WEB_APP_ENDPOINTS string[] = [webAppServiceUri]
