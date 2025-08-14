function Test-ContentAnalyzer {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ResourceEndpoint,

        [Parameter(Mandatory=$true)]
        [string]$SubscriptionKey,

        [Parameter(Mandatory=$true)]
        [string]$AnalyzerName,

        [Parameter(Mandatory=$true)]
        [string]$DocumentUrl,
        
        [Parameter(Mandatory=$false)]
        [string]$SchemaFile,
        
        [Parameter(Mandatory=$false)]
        [switch]$CreateAnalyzer,
        
        [Parameter(Mandatory=$false)]
        [switch]$WaitForCompletion,
        
        [Parameter(Mandatory=$false)]
        [int]$PollIntervalSeconds = 10,
        
        [Parameter(Mandatory=$false)]
        [int]$TimeoutSeconds = 300
    )

    Write-Host "Testing document with analyzer '$AnalyzerName'..." -ForegroundColor Cyan

    # Build the URL
    $apiVersion = "2025-05-01-preview"
    $url = "$ResourceEndpoint/analyzers/$AnalyzerName`:analyze?api-version=$apiVersion&stringEncoding=utf16&enableJailbreakDetection=false"
    
    # Set up headers
    $headers = @{
        "Ocp-Apim-Subscription-Key" = $SubscriptionKey
        "Content-Type" = "application/json"
        "x-ms-useragent" = "cu-sample-code"
    }

    # Create request body
    $body = @{
        url = $DocumentUrl
    } | ConvertTo-Json

    # Step 1: Create analyzer if requested
    if ($CreateAnalyzer) {
        if (-not $SchemaFile) {
            Write-Error "SchemaFile parameter is required when CreateAnalyzer is specified."
            return
        }

        Write-Host "`n=== STEP 1: CREATING ANALYZER ===" -ForegroundColor Magenta
        
        # Import New-ContentAnalyzer function if not already available
        if (-not (Get-Command -Name New-ContentAnalyzer -ErrorAction SilentlyContinue)) {
            . "$PSScriptRoot\Create-ContentAnalyzer.ps1"
        }
        
        $createResult = New-ContentAnalyzer -ResourceEndpoint $ResourceEndpoint -SubscriptionKey $SubscriptionKey -AnalyzerName $AnalyzerName -SchemaFile $SchemaFile
        
        if (-not $createResult) {
            Write-Host "❌ Failed to create analyzer. Aborting test." -ForegroundColor Red
            return
        }
        
        # Give the service a moment to fully register the analyzer
        Write-Host "⏳ Waiting 5 seconds for analyzer to be ready..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
    }

    # Step 2: Process the document
    Write-Host "`n=== STEP 2: SUBMITTING DOCUMENT FOR ANALYSIS ===" -ForegroundColor Magenta
    
    $jobId = $null
    $result = $null
    
    try {
        # Make the API call
        $response = Invoke-WebRequest -Uri $url -Method Post -Headers $headers -Body $body -ContentType "application/json" -ErrorAction Stop
        
        Write-Host "✅ Document analysis initiated successfully!" -ForegroundColor Green
        Write-Host "   Status Code: $($response.StatusCode)" -ForegroundColor Green
        
        # Get the operation-location header
        $operationLocation = $null
        
        # Debug information for headers
        Write-Host "   Debug: Available Headers:" -ForegroundColor Cyan
        $response.Headers.Keys | ForEach-Object {
            Write-Host "     $_ : $($response.Headers[$_])" -ForegroundColor Cyan
        }
        
        if ($response.Headers.ContainsKey('Operation-Location')) {
            $operationLocation = $response.Headers['Operation-Location']
            Write-Host "   Found header 'Operation-Location'" -ForegroundColor Green
        } 
        elseif ($response.Headers.ContainsKey('operation-location')) {
            $operationLocation = $response.Headers['operation-location']
            Write-Host "   Found header 'operation-location'" -ForegroundColor Green
        }
        
        if ($operationLocation) {
            Write-Host "   Operation Location: $operationLocation" -ForegroundColor Green
            # Extract job ID from the operation location - Direct string manipulation approach
            try {
                # Get the part of the URL between /analyzerResults/ and before the ?
                $startIndex = $operationLocation.IndexOf("analyzerResults/")
                if ($startIndex -ge 0) {
                    $startIndex += "analyzerResults/".Length
                    $endIndex = $operationLocation.IndexOf("?", $startIndex)
                    if ($endIndex -gt $startIndex) {
                        $jobId = $operationLocation.Substring($startIndex, $endIndex - $startIndex)
                        Write-Host "   Job ID: $jobId" -ForegroundColor Cyan
                        
                        if (-not $WaitForCompletion) {
                            Write-Host ""
                            Write-Host "To check the status of this job, run:" -ForegroundColor Yellow
                            Write-Host "   .\Manage-ContentAnalyzer.ps1 -Operation Status -ResourceEndpoint '$ResourceEndpoint' -SubscriptionKey '<your-key>' -JobId '$jobId'" -ForegroundColor Yellow
                        }
                    }
                    else {
                        # If no ? found, use the rest of the string
                        $jobId = $operationLocation.Substring($startIndex)
                        Write-Host "   Job ID (no query string): $jobId" -ForegroundColor Cyan
                    }
                }
                else {
                    # Alternative extraction method if regex fails
                    $parts = $operationLocation.Split('/')
                    # Find the part after "analyzerResults"
                    for ($i = 0; $i -lt $parts.Length - 1; $i++) {
                        if ($parts[$i] -eq "analyzerResults" -or $parts[$i] -eq "analyzerResults?") {
                            $jobId = $parts[$i + 1]
                            if ($jobId -match '([^?]+)') {
                                $jobId = $matches[1]
                            }
                            Write-Host "   Job ID (alt method): $jobId" -ForegroundColor Cyan
                            break
                        }
                    }
                    
                    # If still no job ID, just use the whole URL as a fallback
                    if (-not $jobId) {
                        Write-Host "   ⚠️ Could not extract Job ID using normal methods" -ForegroundColor Yellow
                        Write-Host "   Using fallback method" -ForegroundColor Yellow
                        $jobId = [System.IO.Path]::GetFileName($operationLocation.Split('?')[0])
                        Write-Host "   Job ID (fallback): $jobId" -ForegroundColor Cyan
                    }
                }
            }
            catch {
                Write-Host "   ⚠️ Error extracting Job ID: $_" -ForegroundColor Yellow
                # Last resort fallback - use a timestamp as a fake JobId
                $jobId = "fallback-" + (Get-Date).ToString("yyyyMMdd-HHmmss")
                Write-Host "   Using fallback Job ID: $jobId" -ForegroundColor Yellow
            }
        }
        else {
            Write-Host "   ⚠️ Operation Location header not found in response" -ForegroundColor Yellow
        }
        
        $result = @{
            StatusCode = $response.StatusCode
            OperationLocation = $operationLocation
            JobId = $jobId
        }
        
        # Skip waiting for completion if we don't have a job ID
        if (-not $jobId) {
            Write-Host "   ⚠️ Cannot wait for completion without a Job ID" -ForegroundColor Yellow
            return $result
        }
        
        # Step 3: Wait for completion if requested
        if ($WaitForCompletion -and $jobId) {
            Write-Host "`n=== STEP 3: WAITING FOR ANALYSIS TO COMPLETE ===" -ForegroundColor Magenta
            
            # Import Get-ContentAnalyzerStatus function if not already available
            if (-not (Get-Command -Name Get-ContentAnalyzerStatus -ErrorAction SilentlyContinue)) {
                . "$PSScriptRoot\Get-ContentAnalyzerStatus.ps1"
            }
            
            $startTime = Get-Date
            $completed = $false
            $finalResult = $null
            
            while (-not $completed -and ((Get-Date) - $startTime).TotalSeconds -lt $TimeoutSeconds) {
                try {
                    $statusResult = Get-ContentAnalyzerStatus -ResourceEndpoint $ResourceEndpoint -SubscriptionKey $SubscriptionKey -JobId $jobId
                    
                    # Check if statusResult is null (might happen if the Get-ContentAnalyzerStatus function fails)
                    if ($null -eq $statusResult) {
                        Write-Host "⚠️ Failed to retrieve status. Will retry in $PollIntervalSeconds seconds..." -ForegroundColor Yellow
                        Start-Sleep -Seconds $PollIntervalSeconds
                        continue
                    }
                    
                    # Check the status property safely
                    $currentStatus = if ($statusResult.PSObject.Properties['status']) { $statusResult.status } else { "unknown" }
                    
                    if ($currentStatus -eq "succeeded") {
                        $completed = $true
                        $finalResult = $statusResult
                        Write-Host "✅ Analysis completed successfully!" -ForegroundColor Green
                    }
                    elseif ($currentStatus -eq "failed") {
                        $completed = $true
                        $finalResult = $statusResult
                        Write-Host "❌ Analysis failed!" -ForegroundColor Red
                        
                        # If there are errors in the result, display them
                        if ($statusResult.PSObject.Properties['errors'] -and $statusResult.errors) {
                            foreach ($error in $statusResult.errors) {
                                Write-Host "   Error: $($error.message)" -ForegroundColor Red
                            }
                        }
                    }
                    else {
                        Write-Host "⏳ Analysis still in progress... (status: $currentStatus)" -ForegroundColor Yellow
                        Write-Host "   Waiting $PollIntervalSeconds seconds before checking again..." -ForegroundColor Yellow
                        Start-Sleep -Seconds $PollIntervalSeconds
                    }
                }
                catch {
                    Write-Host "⚠️ Error checking status: $_" -ForegroundColor Yellow
                    Write-Host "   Retrying in $PollIntervalSeconds seconds..." -ForegroundColor Yellow
                    Start-Sleep -Seconds $PollIntervalSeconds
                }
            }
            
            if (-not $completed) {
                Write-Host "⚠️ Timeout reached while waiting for analysis to complete." -ForegroundColor Yellow
                Write-Host "   You can check the status later using:" -ForegroundColor Yellow
                Write-Host "   .\Manage-ContentAnalyzer.ps1 -Operation Status -ResourceEndpoint '$ResourceEndpoint' -SubscriptionKey '<your-key>' -JobId '$jobId'" -ForegroundColor Yellow
            }
            
            $result["FinalResult"] = $finalResult
        }
        
        return $result
    }
    catch {
        $errorMessage = $_
        Write-Host "❌ Error testing analyzer: $errorMessage" -ForegroundColor Red
        
        # Add more detailed error information
        Write-Host "   Error Type: $($errorMessage.GetType().FullName)" -ForegroundColor Red
        Write-Host "   Stack Trace:" -ForegroundColor Red
        Write-Host "   $($errorMessage.ScriptStackTrace)" -ForegroundColor Red
        
        if ($errorMessage.Exception) {
            Write-Host "   Exception Type: $($errorMessage.Exception.GetType().FullName)" -ForegroundColor Red
            Write-Host "   Exception Message: $($errorMessage.Exception.Message)" -ForegroundColor Red
        }
        
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
        
        # Return a minimal result object that won't cause additional errors
        return @{
            StatusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode } else { "Error" }
            Error = $errorMessage.ToString()
            JobId = $null
            OperationLocation = $null
        }
    }
}
