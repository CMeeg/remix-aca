$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "[preprovision] === Setting azd env vars from local `.env` file ==="

# Run script to set azd env vars from local env vars i.e. from `.env` file
& $(Join-Path $scriptDir "../scripts/azd-env-set-from-local.ps1")

Write-Host ""
