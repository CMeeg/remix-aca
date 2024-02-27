function Merge-EnvFiles {
    param(
        [Parameter(Mandatory=$true)]
        [string]$base,
        [Parameter(Mandatory=$true)]
        [string]$with,
        [Parameter(Mandatory=$true)]
        [string]$output
    )

    $hash = @{}

    Get-Content $base,$with | ForEach-Object {
        $key, $value = $_ -split '=', 2

        if (($null -ne $key) -and ($key -ne "") -and ($key.StartsWith("#") -eq $false)) {
            $hash[$key] = $value
        }
    }

    $hash.Keys | Sort-Object | ForEach-Object {
        "$_=$($hash[$_])"
    } | Out-File $output
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Merge the azd env file (output from running `azd provision`) with the local env file - if there are duplicate keys the values from the azd env file will take precedence

Write-Host ""
Write-Host "[postprovision] === Creating `.env.azure` file ==="

# Before we can build the app we need to merge the local env file (if one exists) with the azd env file as it contains values required for the build to succeed
$envLocal = Join-Path $scriptDir "../../.env"
$envAzd = Join-Path $scriptDir "../../.azure/${env:AZURE_ENV_NAME}/.env"

# The result will be output to this location and the Dockerfile will copy and rename it to .env during the build step
$envAzure = Join-Path $scriptDir "../../.env.azure"

if (!(Test-Path $envLocal -PathType Leaf)) {
    # local env file does not exist so just copy the azd env file to .env.azure
    Copy-Item $envAzd -Destination $envAzure

    return
}

Merge-EnvFiles -base $envLocal -with $envAzd -output $envAzure

# Write domain verification vars to output so they can be referenced if needed

Write-Host ""
Write-Host "[postprovision] === Container apps domain verification ==="

$envAzd = azd env get-values --output json | ConvertFrom-Json

# Output info required for domain verification
Write-Host "Static IP: $($envAzd.AZURE_CONTAINER_STATIC_IP)"
Write-Host "FQDN: $($envAzd.SERVICE_WEB_APP_FQDN)"
Write-Host "Verification code: $($envAzd.AZURE_CONTAINER_DOMAIN_VERIFICATION_CODE)"

Write-Host ""
