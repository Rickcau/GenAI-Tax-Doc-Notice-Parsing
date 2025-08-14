<#
.SYNOPSIS
    Manages Azure AI Content Understanding custom analyzers
.DESCRIPTION
    This script provides a user-friendly interface for creating, testing, and managing
    custom analyzers with Azure AI Content Understanding.
.PARAMETER Operation
    The operation to perform: Create, Test, Status, List, Delete, Workflow
.PARAMETER ResourceEndpoint
    The Azure Content Understanding resource endpoint URL
.PARAMETER SubscriptionKey
    The Azure Content Understanding subscription key
.PARAMETER AnalyzerName
    The name of the custom analyzer to create or operate on
.PARAMETER SchemaFile
    Path to the schema JSON file for analyzer creation
.PARAMETER DocumentUrl
    URL to the document to analyze (for Test operation)
.PARAMETER JobId
    Job ID for checking status (for Status operation)
.PARAMETER CreateAnalyzer
    For Workflow operation: Whether to create a new analyzer before testing
.PARAMETER WaitForCompletion
    For Workflow/Test operations: Whether to wait for analysis to complete
.PARAMETER TimeoutSeconds
    For Workflow/Test operations: Maximum seconds to wait for completion
.PARAMETER PollIntervalSeconds
    For Workflow/Test operations: Seconds between status checks
.EXAMPLE
    .\Manage-ContentAnalyzer.ps1 -Operation Create -ResourceEndpoint "https://your-resource.cognitiveservices.azure.com/contentunderstanding" -SubscriptionKey "your-key" -AnalyzerName "Custom-Tax-Analyzer" -SchemaFile ".\Tax-Doc-Analyzer-Schema.json"
.EXAMPLE
    .\Manage-ContentAnalyzer.ps1 -Operation Test -ResourceEndpoint "https://your-resource.cognitiveservices.azure.com/contentunderstanding" -SubscriptionKey "your-key" -AnalyzerName "Custom-Tax-Analyzer" -DocumentUrl "https://storage-account.blob.core.windows.net/container/document.pdf"
.EXAMPLE
    .\Manage-ContentAnalyzer.ps1 -Operation Status -ResourceEndpoint "https://your-resource.cognitiveservices.azure.com/contentunderstanding" -SubscriptionKey "your-key" -JobId "job-id"
.EXAMPLE
    .\Manage-ContentAnalyzer.ps1 -Operation List -ResourceEndpoint "https://your-resource.cognitiveservices.azure.com/contentunderstanding" -SubscriptionKey "your-key"
.EXAMPLE
    .\Manage-ContentAnalyzer.ps1 -Operation Delete -ResourceEndpoint "https://your-resource.cognitiveservices.azure.com/contentunderstanding" -SubscriptionKey "your-key" -AnalyzerName "Custom-Tax-Analyzer"
.EXAMPLE
    .\Manage-ContentAnalyzer.ps1 -Operation Workflow -ResourceEndpoint "https://your-resource.cognitiveservices.azure.com/contentunderstanding" -SubscriptionKey "your-key" -AnalyzerName "Custom-Tax-Analyzer" -SchemaFile ".\Tax-Doc-Analyzer-Schema.json" -DocumentUrl "https://storage-account.blob.core.windows.net/container/document.pdf" -CreateAnalyzer -WaitForCompletion
#>

param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("Create", "Test", "Status", "List", "Delete", "Workflow")]
    [string]$Operation,

    [Parameter(Mandatory=$true)]
    [string]$ResourceEndpoint,

    [Parameter(Mandatory=$true)]
    [string]$SubscriptionKey,

    [Parameter(Mandatory=$false)]
    [string]$AnalyzerName,

    [Parameter(Mandatory=$false)]
    [string]$SchemaFile,

    [Parameter(Mandatory=$false)]
    [string]$DocumentUrl,

    [Parameter(Mandatory=$false)]
    [string]$JobId,

    [Parameter(Mandatory=$false)]
    [switch]$CreateAnalyzer,

    [Parameter(Mandatory=$false)]
    [switch]$WaitForCompletion,

    [Parameter(Mandatory=$false)]
    [int]$TimeoutSeconds = 300,

    [Parameter(Mandatory=$false)]
    [int]$PollIntervalSeconds = 5
)

# Import helper functions
. "$PSScriptRoot\Create-ContentAnalyzer.ps1" # Contains New-ContentAnalyzer function
. "$PSScriptRoot\Test-ContentAnalyzer.ps1"
. "$PSScriptRoot\Get-ContentAnalyzerStatus.ps1"
. "$PSScriptRoot\List-ContentAnalyzers.ps1" # Contains Get-ContentAnalyzers function
. "$PSScriptRoot\Remove-ContentAnalyzer.ps1"

# Remove trailing slash from endpoint if present
if ($ResourceEndpoint.EndsWith("/")) {
    $ResourceEndpoint = $ResourceEndpoint.TrimEnd("/")
}

# Parameter validation based on operation
switch ($Operation) {
    "Create" {
        if ([string]::IsNullOrEmpty($AnalyzerName) -or [string]::IsNullOrEmpty($SchemaFile)) {
            Write-Error "AnalyzerName and SchemaFile are required for Create operation"
            exit 1
        }
        if (-not (Test-Path $SchemaFile)) {
            Write-Error "Schema file not found: $SchemaFile"
            exit 1
        }
        New-ContentAnalyzer -ResourceEndpoint $ResourceEndpoint -SubscriptionKey $SubscriptionKey -AnalyzerName $AnalyzerName -SchemaFile $SchemaFile
    }
    "Test" {
        if ([string]::IsNullOrEmpty($AnalyzerName) -or [string]::IsNullOrEmpty($DocumentUrl)) {
            Write-Error "AnalyzerName and DocumentUrl are required for Test operation"
            exit 1
        }
        Test-ContentAnalyzer -ResourceEndpoint $ResourceEndpoint -SubscriptionKey $SubscriptionKey -AnalyzerName $AnalyzerName -DocumentUrl $DocumentUrl -WaitForCompletion:$WaitForCompletion -TimeoutSeconds $TimeoutSeconds -PollIntervalSeconds $PollIntervalSeconds
    }
    "Status" {
        if ([string]::IsNullOrEmpty($JobId)) {
            Write-Error "JobId is required for Status operation"
            exit 1
        }
        Get-ContentAnalyzerStatus -ResourceEndpoint $ResourceEndpoint -SubscriptionKey $SubscriptionKey -JobId $JobId
    }
    "List" {
        Get-ContentAnalyzers -ResourceEndpoint $ResourceEndpoint -SubscriptionKey $SubscriptionKey
    }
    "Delete" {
        if ([string]::IsNullOrEmpty($AnalyzerName)) {
            Write-Error "AnalyzerName is required for Delete operation"
            exit 1
        }
        Remove-ContentAnalyzer -ResourceEndpoint $ResourceEndpoint -SubscriptionKey $SubscriptionKey -AnalyzerName $AnalyzerName
    }
    "Workflow" {
        if ([string]::IsNullOrEmpty($AnalyzerName) -or [string]::IsNullOrEmpty($DocumentUrl)) {
            Write-Error "AnalyzerName and DocumentUrl are required for Workflow operation"
            exit 1
        }
        
        if ($CreateAnalyzer -and [string]::IsNullOrEmpty($SchemaFile)) {
            Write-Error "SchemaFile is required when CreateAnalyzer is specified"
            exit 1
        }
        
        if ($CreateAnalyzer -and -not (Test-Path $SchemaFile)) {
            Write-Error "Schema file not found: $SchemaFile"
            exit 1
        }
        
        Write-Host "==== CONTENT ANALYZER WORKFLOW ====" -ForegroundColor Cyan
        Write-Host "Resource: $ResourceEndpoint" -ForegroundColor Cyan
        Write-Host "Analyzer: $AnalyzerName" -ForegroundColor Cyan
        Write-Host "Document: $DocumentUrl" -ForegroundColor Cyan
        if ($CreateAnalyzer) {
            Write-Host "Schema: $SchemaFile" -ForegroundColor Cyan
        }
        Write-Host "===============================" -ForegroundColor Cyan
        
        try {
            $result = Test-ContentAnalyzer -ResourceEndpoint $ResourceEndpoint -SubscriptionKey $SubscriptionKey `
                            -AnalyzerName $AnalyzerName -DocumentUrl $DocumentUrl `
                            -CreateAnalyzer:$CreateAnalyzer -SchemaFile $SchemaFile `
                            -WaitForCompletion:$WaitForCompletion `
                            -TimeoutSeconds $TimeoutSeconds -PollIntervalSeconds $PollIntervalSeconds
            
            # Check if we got a valid result with a JobId
            if ($result -and $result.JobId) {
                Write-Host "✅ Workflow completed successfully with Job ID: $($result.JobId)" -ForegroundColor Green
            }
            elseif ($result -and $result.Error) {
                Write-Host "❌ Workflow failed with error: $($result.Error)" -ForegroundColor Red
            }
            else {
                Write-Host "⚠️ Workflow completed with unexpected result" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "❌ Unhandled error in workflow operation: $_" -ForegroundColor Red
        }
    }
}
