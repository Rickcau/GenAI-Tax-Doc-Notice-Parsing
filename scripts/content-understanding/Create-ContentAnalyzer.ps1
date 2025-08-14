function New-ContentAnalyzer {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ResourceEndpoint,

        [Parameter(Mandatory=$true)]
        [string]$SubscriptionKey,

        [Parameter(Mandatory=$true)]
        [string]$AnalyzerName,

        [Parameter(Mandatory=$true)]
        [string]$SchemaFile
    )

    Write-Host "Creating custom analyzer '$AnalyzerName'..." -ForegroundColor Cyan

    # Build the URL
    $apiVersion = "2025-05-01-preview"
    $url = "$ResourceEndpoint/analyzers/$AnalyzerName`?api-version=$apiVersion&stringEncoding=utf16&enableJailbreakDetection=false"
    
    # Set up headers
    $headers = @{
        "Ocp-Apim-Subscription-Key" = $SubscriptionKey
        "Content-Type" = "application/json"
        "x-ms-useragent" = "cu-sample-code"
    }

    try {
        # Read the schema file
        $schemaContent = Get-Content -Path $SchemaFile -Raw

        # Validate JSON
        try {
            $null = $schemaContent | ConvertFrom-Json
        } catch {
            Write-Error "Invalid JSON in schema file: $_"
            return
        }

        # Make the API call
        $response = Invoke-RestMethod -Uri $url -Method Put -Headers $headers -Body $schemaContent -ContentType "application/json" -ErrorAction Stop
        
        Write-Host "✅ Custom analyzer '$AnalyzerName' created successfully!" -ForegroundColor Green
        return $response
    }
    catch {
        Write-Host "❌ Error creating analyzer: $_" -ForegroundColor Red
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode
            Write-Host "   Status code: $statusCode" -ForegroundColor Red
            
            try {
                $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                $errorContent = $reader.ReadToEnd()
                Write-Host "   Error details: $errorContent" -ForegroundColor Red
            }
            catch {
                Write-Host "   Could not read error response details" -ForegroundColor Red
            }
        }
    }
}
