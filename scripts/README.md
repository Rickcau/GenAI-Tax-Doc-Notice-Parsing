# Azure AI Content Understanding Scripts for Tax Document Processing

This repository contains PowerShell scripts to help you work with Azure AI Content Understanding for tax document processing. These scripts simplify the process of creating custom analyzers, testing documents, and managing the complete workflow for tax document analysis.

## Overview

Azure AI Content Understanding allows you to create custom analyzers that can extract structured data from unstructured documents like tax notices and forms. These scripts provide a user-friendly interface for:

- Creating and updating custom analyzers with your schema
- Testing document analysis against your custom analyzers
- Checking the status of document analysis jobs
- Listing all available analyzers (both custom and prebuilt)
- Deleting custom analyzers when no longer needed

## Script Files

| Script Name | Description |
|-------------|-------------|
| `Manage-ContentAnalyzer.ps1` | Main script that orchestrates all operations |
| `Create-ContentAnalyzer.ps1` | Contains the `New-ContentAnalyzer` function for creating custom analyzers |
| `Test-ContentAnalyzer.ps1` | Tests documents against your custom analyzers |
| `Get-ContentAnalyzerStatus.ps1` | Checks job status and displays results |
| `List-ContentAnalyzers.ps1` | Contains the `Get-ContentAnalyzers` function for listing analyzers |
| `Remove-ContentAnalyzer.ps1` | Deletes custom analyzers |
| `Example-Tax-Analyzer-Schema.json` | Example schema file for tax document analysis |

## Prerequisites

- An Azure account with an Azure AI Content Understanding resource
- PowerShell 7.0 or later
- Access to tax documents (PDF, DOCX, etc.) stored in Azure Blob Storage or accessible via URL

## Getting Started

### 1. Clone or download this repository

Ensure all script files are in the same directory.

### 2. Prepare your analyzer schema

You can use the provided `Example-Tax-Analyzer-Schema.json` as a starting point and customize it based on your specific tax document analysis needs. The schema defines what fields you want to extract from tax documents.

### 3. Choose your operation

All operations are performed through the main script `Manage-ContentAnalyzer.ps1` with different operation parameters.

| Operation | Description |
|-----------|-------------|
| `Create` | Creates a new custom analyzer with the specified schema |
| `Test` | Tests a document against an existing analyzer |
| `Status` | Checks the status of an analysis job and displays results |
| `List` | Lists all available analyzers (custom and prebuilt) |
| `Delete` | Deletes a custom analyzer |
| `Workflow` | Performs an end-to-end process: create analyzer, analyze document, and display results |

## Usage Examples

### Creating a Custom Analyzer

```powershell
.\Manage-ContentAnalyzer.ps1 `
    -Operation Create `
    -ResourceEndpoint "https://your-resource.cognitiveservices.azure.com/contentunderstanding" `
    -SubscriptionKey "your-subscription-key" `
    -AnalyzerName "Tax-Document-Analyzer" `
    -SchemaFile ".\Example-Tax-Analyzer-Schema.json"
```

This creates a custom analyzer named "Tax-Document-Analyzer" using the schema defined in the specified file.

### Testing a Document

```powershell
.\Manage-ContentAnalyzer.ps1 `
    -Operation Test `
    -ResourceEndpoint "https://your-resource.cognitiveservices.azure.com/contentunderstanding" `
    -SubscriptionKey "your-subscription-key" `
    -AnalyzerName "Tax-Document-Analyzer" `
    -DocumentUrl "https://storage-account.blob.core.windows.net/container/tax_document.pdf"
```

This submits a tax document for analysis and returns a Job ID for tracking.

### End-to-End Workflow (New!)

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

This performs a complete workflow:
1. Creates a custom analyzer using the specified schema
2. Submits a document for analysis
3. Waits for the analysis to complete
4. Displays the analysis results

### Checking Job Status

```powershell
.\Manage-ContentAnalyzer.ps1 `
    -Operation Status `
    -ResourceEndpoint "https://your-resource.cognitiveservices.azure.com/contentunderstanding" `
    -SubscriptionKey "your-subscription-key" `
    -JobId "job-id-from-test-operation"
```

This checks the status of an analysis job and displays the extracted data when complete.

### Listing All Analyzers

```powershell
.\Manage-ContentAnalyzer.ps1 `
    -Operation List `
    -ResourceEndpoint "https://your-resource.cognitiveservices.azure.com/contentunderstanding" `
    -SubscriptionKey "your-subscription-key"
```

This displays all available analyzers, both custom and prebuilt.

### Deleting a Custom Analyzer

```powershell
.\Manage-ContentAnalyzer.ps1 `
    -Operation Delete `
    -ResourceEndpoint "https://your-resource.cognitiveservices.azure.com/contentunderstanding" `
    -SubscriptionKey "your-subscription-key" `
    -AnalyzerName "Tax-Document-Analyzer"
```

This deletes a custom analyzer (includes confirmation prompt).

## Customizing for Specific Tax Documents

The example schema includes fields commonly found in tax documents:

- taxpayer_name
- tax_jurisdiction
- tax_type
- tax_period
- amount_due
- due_date

You can customize the schema by:

1. Adding more fields specific to your tax documents
2. Modifying field descriptions to improve extraction accuracy
3. Adjusting configuration options like enabling/disabling OCR

## Output and Results

- All operations provide color-coded console output for easy status tracking
- Document analysis results are saved as JSON files for further processing
- Detailed error messages help troubleshoot API or connection issues

## Security Best Practices

- Never commit scripts containing your subscription keys to source control
- Consider using Azure Key Vault for secure key management
- Use environment variables or secure configuration files for storing credentials
- Review Azure RBAC permissions to ensure least privilege access

## Troubleshooting

- **403 Forbidden errors**: Check your subscription key and that your Azure resource allows your IP address
- **404 Not Found errors**: Verify the analyzer name or if the document URL is accessible
- **Long-running jobs**: Some complex documents may take longer to analyze
- **Schema validation errors**: Ensure your JSON schema follows the Content Understanding format

## Advanced Usage

### Processing Multiple Documents

You can create a simple loop to process multiple documents:

```powershell
$documents = @(
    "https://storage.blob.core.windows.net/tax-docs/doc1.pdf",
    "https://storage.blob.core.windows.net/tax-docs/doc2.pdf"
)

foreach ($doc in $documents) {
    .\Manage-ContentAnalyzer.ps1 -Operation Test -ResourceEndpoint "your-endpoint" -SubscriptionKey "your-key" -AnalyzerName "Tax-Analyzer" -DocumentUrl $doc
}
```

### Updating an Existing Analyzer

To update an existing analyzer, use the Create operation with the same analyzer name:

```powershell
.\Manage-ContentAnalyzer.ps1 -Operation Create -ResourceEndpoint "your-endpoint" -SubscriptionKey "your-key" -AnalyzerName "Tax-Analyzer" -SchemaFile ".\Updated-Schema.json"
```

## References

- [Azure Content Understanding documentation](https://learn.microsoft.com/en-us/azure/cognitive-services/content-understanding/)
- [API Reference](https://learn.microsoft.com/en-us/rest/api/cognitiveservices/contentunderstanding/analyzers)

## Contributing

Feel free to customize these scripts for your specific needs or contribute improvements:

1. Fork this repository
2. Make your changes
3. Submit a pull request with a description of your improvements

## License

This project is licensed under the MIT License - see the LICENSE file for details.
