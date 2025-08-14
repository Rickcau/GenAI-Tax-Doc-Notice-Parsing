function Get-ContentAnalyzers {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ResourceEndpoint,

        [Parameter(Mandatory=$true)]
        [string]$SubscriptionKey
    )

    Write-Host "Listing available analyzers..." -ForegroundColor Cyan

    # Build the URL
    $apiVersion = "2025-05-01-preview"
    $url = "$ResourceEndpoint/analyzers?api-version=$apiVersion"
    
    # Set up headers
    $headers = @{
        "Ocp-Apim-Subscription-Key" = $SubscriptionKey
        "x-ms-useragent" = "cu-sample-code"
    }

    try {
        # Make the API call
        $response = Invoke-RestMethod -Uri $url -Method Get -Headers $headers -ErrorAction Stop
        
        # Process and display the results
        $customAnalyzers = @()
        $prebuiltAnalyzers = @()
        
        foreach ($analyzer in $response.analyzers) {
            # Determine if this is a prebuilt or custom analyzer
            $isPrebuilt = $analyzer.name -match "^prebuilt-"
            
            $analyzerInfo = [PSCustomObject]@{
                Name = $analyzer.name
                Description = $analyzer.description
                ApiVersion = $analyzer.apiVersion
                Type = if ($isPrebuilt) { "Prebuilt" } else { "Custom" }
            }
            
            if ($isPrebuilt) {
                $prebuiltAnalyzers += $analyzerInfo
            } else {
                $customAnalyzers += $analyzerInfo
            }
        }
        
        # Display Custom Analyzers
        if ($customAnalyzers.Count -gt 0) {
            Write-Host "`nCustom Analyzers:" -ForegroundColor Green
            $customAnalyzers | Format-Table -AutoSize
        } else {
            Write-Host "`nNo custom analyzers found." -ForegroundColor Yellow
        }
        
        # Display Prebuilt Analyzers
        if ($prebuiltAnalyzers.Count -gt 0) {
            Write-Host "`nPrebuilt Analyzers:" -ForegroundColor Cyan
            $prebuiltAnalyzers | Format-Table -AutoSize
        }
        
        # Save the complete results to a file
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $outputFile = "analyzers_list_${timestamp}.json"
        $response | ConvertTo-Json -Depth 10 | Out-File -FilePath $outputFile
        
        Write-Host "`nComplete analyzer list saved to: $outputFile" -ForegroundColor Cyan
        
        return $response
    }
    catch {
        Write-Host "❌ Error listing analyzers: $_" -ForegroundColor Red
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
