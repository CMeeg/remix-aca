function Remove-Quotes {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$value,
        [string]$quoteChar = '"'
    )

    if ($value.StartsWith($quoteChar) -and $value.EndsWith($quoteChar)) {
        return $value.Substring(1, $value.Length - 2)
    }

    return $value
}

function Read-EnvVars {
    param(
        [Parameter(Mandatory = $true)]
        [string]$path
    )

    $envVars = @{}

    if (!(Test-Path $path -PathType Leaf)) {
        # File does not exist so there is nothing to do

        return $envVars
    }

    $content = Get-Content -raw $path | ConvertFrom-StringData

    $content.GetEnumerator() | Foreach-Object {
        $key, $value = $_.Name, $_.Value

        if (($null -eq $value) -or ($value.Trim() -eq "") -or ($value.Trim().StartsWith("#"))) {
            $envVars[$key] = ""
        } else {
            $value = Remove-Quotes -value $value -quoteChar '"'
            $value = Remove-Quotes -value $value -quoteChar "'"

            $envVars[$key] = $value
        }
    }

    return $envVars
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Read `.env` file into memory

$envPath = Join-Path $scriptDir "../../.env"
$env = Read-EnvVars -path $envPath

# Loop through each key/value pair and set the corresponding environment variable using `azd env set` command

foreach ($key in $env.Keys) {
    $value = $env[$key]
    azd env set $key $value --no-prompt
}
