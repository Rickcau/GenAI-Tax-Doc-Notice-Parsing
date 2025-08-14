function Get-ContentAnalyzerStatus {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ResourceEndpoint,

        [Parameter(Mandatory=$true)]
        [string]$SubscriptionKey,

        [Parameter(Mandatory=$true)]
        [string]$JobId
    )

    Write-Host "Checking status of job '$JobId'..." -ForegroundColor Cyan

    # Build the URL
    $apiVersion = "2025-05-01-preview"
    $url = "$ResourceEndpoint/analyzerResults/$JobId`?api-version=$apiVersion"
    
    # Set up headers
    $headers = @{
        "Ocp-Apim-Subscription-Key" = $SubscriptionKey
        "Content-Type" = "application/json"
        "x-ms-useragent" = "cu-sample-code"
    }

    try {
        # Make the API call
        $response = Invoke-RestMethod -Uri $url -Method Get -Headers $headers -ErrorAction Stop
        
        # Check the status
        $status = $response.status
        Write-Host "Current status: $status" -ForegroundColor Cyan
        
        switch ($status) {
            "notStarted" {
                Write-Host "⏳ Job not started yet..." -ForegroundColor Yellow
            }
            "running" {
                Write-Host "⏳ Job is still running..." -ForegroundColor Yellow
                Write-Host "Run this command again in a few moments to check the status." -ForegroundColor Yellow
            }
            "succeeded" {
                Write-Host "✅ Job completed successfully!" -ForegroundColor Green
                
                # Save the results to a file
                $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
                $outputFile = "analyzer_results_${JobId}_${timestamp}.json"
                $response | ConvertTo-Json -Depth 10 | Out-File -FilePath $outputFile
                
                Write-Host "Results saved to: $outputFile" -ForegroundColor Green
                
                # Display a summary of the results
                Write-Host "`nResult Summary:" -ForegroundColor Cyan
                
                # Check for null values and proper structure at each level
                if ($response.analyzeResult -and $response.analyzeResult.PSObject.Properties['documentResults'] -and $response.analyzeResult.documentResults) {
                    foreach ($docResult in $response.analyzeResult.documentResults) {
                        Write-Host "  Document:" -ForegroundColor Cyan
                        
                        # Display fields extracted
                        if ($docResult -and $docResult.PSObject.Properties['fields'] -and $docResult.fields) {
                            Write-Host "  Fields:" -ForegroundColor Cyan
                            foreach ($fieldName in $docResult.fields.PSObject.Properties.Name) {
                                if ($docResult.fields.$fieldName -and $docResult.fields.$fieldName.PSObject.Properties['content']) {
                                    $value = $docResult.fields.$fieldName.content
                                    Write-Host "    - $fieldName`: $value" -ForegroundColor White
                                }
                                else {
                                    Write-Host "    - $fieldName`: [No content available]" -ForegroundColor Yellow
                                }
                            }
                        }
                        else {
                            Write-Host "  No fields found in the document result" -ForegroundColor Yellow
                        }
                    }
                }
                else {
                    Write-Host "  No document results found in the response" -ForegroundColor Yellow
                    Write-Host "  Raw response structure:" -ForegroundColor Yellow
                    $response | Format-List | Out-String | Write-Host -ForegroundColor Yellow
                }
            }
            "failed" {
                Write-Host "❌ Job failed!" -ForegroundColor Red
                if ($response.errors) {
                    foreach ($errorItem in $response.errors) {
                        Write-Host "  Error: $($errorItem.message)" -ForegroundColor Red
                    }
                }
            }
            default {
                Write-Host "Status: $status" -ForegroundColor Yellow
            }
        }
        
        return $response
    }
    catch {
        Write-Host "❌ Error checking job status: $_" -ForegroundColor Red
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
