function Remove-ContentAnalyzer {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ResourceEndpoint,

        [Parameter(Mandatory=$true)]
        [string]$SubscriptionKey,

        [Parameter(Mandatory=$true)]
        [string]$AnalyzerName
    )

    Write-Host "Deleting custom analyzer '$AnalyzerName'..." -ForegroundColor Cyan

    # Confirm deletion
    $confirmation = Read-Host "Are you sure you want to delete the analyzer '$AnalyzerName'? (Y/N)"
    if ($confirmation -ne 'Y' -and $confirmation -ne 'y') {
        Write-Host "Deletion cancelled." -ForegroundColor Yellow
        return
    }

    # Build the URL
    $apiVersion = "2025-05-01-preview"
    $url = "$ResourceEndpoint/analyzers/$AnalyzerName`?api-version=$apiVersion"
    
    # Set up headers
    $headers = @{
        "Ocp-Apim-Subscription-Key" = $SubscriptionKey
        "x-ms-useragent" = "cu-sample-code"
    }

    try {
        # Make the API call
        $response = Invoke-WebRequest -Uri $url -Method Delete -Headers $headers -ErrorAction Stop
        
        Write-Host "✅ Custom analyzer '$AnalyzerName' deleted successfully!" -ForegroundColor Green
        Write-Host "   Status Code: $($response.StatusCode)" -ForegroundColor Green
        
        return $response.StatusCode
    }
    catch {
        Write-Host "❌ Error deleting analyzer: $_" -ForegroundColor Red
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode
            Write-Host "   Status code: $statusCode" -ForegroundColor Red
            
            if ($statusCode -eq 404) {
                Write-Host "   Analyzer '$AnalyzerName' not found. It may have already been deleted or never existed." -ForegroundColor Yellow
            }
            else {
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
}
