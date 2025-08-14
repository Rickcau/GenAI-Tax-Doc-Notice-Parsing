# Content Understanding Scripts for Tax Document Analysis

This folder### 5. List All Analyzers

```powershell
.\Manage-ContentAnalyzer.ps1 `
    -Operation List `
    -ResourceEndpoint "https://your-resource.cognitiveservices.azure.com/contentunderstanding" `
    -SubscriptionKey "your-subscription-key"
```

### 6. Delete a Custom AnalyzerPowerShell scripts to help you create, test, and manage custom analyzers with Azure AI Content Understanding for tax document processing.

## Prerequisites

- An Azure account with an Azure AI Content Understanding resource
- PowerShell 7.0 or later
- Basic understanding of Azure AI Content Understanding

## Script Overview

- `Manage-ContentAnalyzer.ps1`: Main script that orchestrates all operations
- `Create-ContentAnalyzer.ps1`: Creates a custom analyzer using a JSON schema file
- `Test-ContentAnalyzer.ps1`: Tests a document against a custom analyzer and optionally waits for results
- `Get-ContentAnalyzerStatus.ps1`: Checks the status of a document analysis job
- `List-ContentAnalyzers.ps1`: Lists all available analyzers (custom and prebuilt)
- `Remove-ContentAnalyzer.ps1`: Deletes a custom analyzer
- `Example-Tax-Analyzer-Schema.json`: Example schema file for creating a tax document analyzer

## Quick Start

### 1. Create a Custom Analyzer

```powershell
.\Manage-ContentAnalyzer.ps1 `
    -Operation Create `
    -ResourceEndpoint "https://your-resource.cognitiveservices.azure.com/contentunderstanding" `
    -SubscriptionKey "your-subscription-key" `
    -AnalyzerName "Tax-Document-Analyzer" `
    -SchemaFile ".\Example-Tax-Analyzer-Schema.json"
```

### 2. Test a Document

```powershell
.\Manage-ContentAnalyzer.ps1 `
    -Operation Test `
    -ResourceEndpoint "https://your-resource.cognitiveservices.azure.com/contentunderstanding" `
    -SubscriptionKey "your-subscription-key" `
    -AnalyzerName "Tax-Document-Analyzer" `
    -DocumentUrl "https://storage-account.blob.core.windows.net/container/tax_document.pdf"
```

### 3. End-to-End Workflow (NEW!)

This performs a complete workflow in one command:

```powershell
.\Manage-ContentAnalyzer.ps1 `
    -Operation Workflow `
    -ResourceEndpoint "https://your-resource.cognitiveservices.azure.com/contentunderstanding" `
    -SubscriptionKey "your-subscription-key" `
    -AnalyzerName "Tax-Document-Analyzer" `
    -SchemaFile ".\Example-Tax-Analyzer-Schema.json" `
    -DocumentUrl "https://storage-account.blob.core.windows.net/container/tax_document.pdf" `
    -CreateAnalyzer `
    -WaitForCompletion
```

### 4. Check Job Status

After testing a document, you'll get a Job ID. Use it to check the status:

```powershell
.\Manage-ContentAnalyzer.ps1 `
    -Operation Status `
    -ResourceEndpoint "https://your-resource.cognitiveservices.azure.com/contentunderstanding" `
    -SubscriptionKey "your-subscription-key" `
    -JobId "job-id-from-test-operation"
```

### 4. List All Analyzers

```powershell
.\Manage-ContentAnalyzer.ps1 `
    -Operation List `
    -ResourceEndpoint "https://your-resource.cognitiveservices.azure.com/contentunderstanding" `
    -SubscriptionKey "your-subscription-key"
```

### 5. Delete a Custom Analyzer

```powershell
.\Manage-ContentAnalyzer.ps1 `
    -Operation Delete `
    -ResourceEndpoint "https://your-resource.cognitiveservices.azure.com/contentunderstanding" `
    -SubscriptionKey "your-subscription-key" `
    -AnalyzerName "Tax-Document-Analyzer"
```

## Customizing the Schema

The example schema file (`Example-Tax-Analyzer-Schema.json`) includes basic fields for tax document analysis. You can modify this file to include additional fields or change field descriptions based on your specific needs.

## Security Note

Never store your Azure subscription key in scripts or commit it to source control. Consider using Azure Key Vault or environment variables for secure key management in production environments.

## Troubleshooting

- If you encounter permission issues, ensure your Azure account has sufficient permissions to manage the Content Understanding resource.
- For API-related errors, check the error details in the console output for more information.
- If document analysis is taking too long, the process might be still running in the background. Continue to check the status using the Job ID.
