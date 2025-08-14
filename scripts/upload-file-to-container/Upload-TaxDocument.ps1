# Azure Blob Upload Script with Tax Document Metadata
# This script uploads a file to Azure Blob Storage with comprehensive tax document metadata

param(
    [Parameter(Mandatory=$true)]
    [string]$FilePath,
    
    [Parameter(Mandatory=$false)]
    [string]$StorageAccountName = "stgcdmtaxdocswest",
    
    [Parameter(Mandatory=$false)]
    [string]$ContainerName = "incoming",
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "your-resource-group-name",
    
    # Tax Document Metadata Parameters
    [Parameter(Mandatory=$false)]
    [string]$TaxpayerName = "",
    
    [Parameter(Mandatory=$false)]
    [string]$TaxJurisdiction = "",
    
    [Parameter(Mandatory=$false)]
    [string]$NoticeType = "",
    
    [Parameter(Mandatory=$false)]
    [string]$EinTaxId = "",
    
    [Parameter(Mandatory=$false)]
    [string]$TotalAmountDue = "",
    
    [Parameter(Mandatory=$false)]
    [string]$FilingDeadline = "",
    
    [Parameter(Mandatory=$false)]
    [string]$NoticeNumber = "",
    
    [Parameter(Mandatory=$false)]
    [string]$NoticeDate = "",
    
    [Parameter(Mandatory=$false)]
    [string]$TaxpayerAddress = "",
    
    [Parameter(Mandatory=$false)]
    [string]$TaxAuthorityAddress = "",
    
    [Parameter(Mandatory=$false)]
    [string]$TaxPeriod = "",
    
    [Parameter(Mandatory=$false)]
    [string]$ActionNeeded = "",
    
    [Parameter(Mandatory=$false)]
    [string]$EmailId = "",
    
    [Parameter(Mandatory=$false)]
    [string]$MessageId = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Status = "pending"
)

# Function to validate file exists
function Test-FileExists {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        Write-Error "File not found: $Path"
        exit 1
    }
    
    Write-Host "✓ File found: $Path" -ForegroundColor Green
}

# Function to connect to Azure
function Connect-ToAzure {
    try {
        Write-Host "Checking Azure connection..." -ForegroundColor Yellow
        $context = Get-AzContext
        
        if (-not $context) {
            Write-Host "Connecting to Azure..." -ForegroundColor Yellow
            Connect-AzAccount
        } else {
            Write-Host "✓ Already connected to Azure as: $($context.Account.Id)" -ForegroundColor Green
        }
    }
    catch {
        Write-Error "Failed to connect to Azure: $($_.Exception.Message)"
        exit 1
    }
}

# Function to get storage context
function Get-StorageContext {
    param(
        [string]$StorageAccountName,
        [string]$ResourceGroupName
    )
    
    try {
        Write-Host "Getting storage account context..." -ForegroundColor Yellow
        $storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ErrorAction Stop
        return $storageAccount.Context
    }
    catch {
        Write-Error "Failed to get storage account context: $($_.Exception.Message)"
        Write-Host "Make sure the storage account '$StorageAccountName' exists in resource group '$ResourceGroupName'" -ForegroundColor Red
        exit 1
    }
}

# Function to create metadata hashtable
function New-MetadataHashtable {
    $metadata = @{}
    
    # Only add metadata if values are provided (not empty)
    if ($TaxpayerName) { $metadata["taxpayer_name"] = $TaxpayerName }
    if ($TaxJurisdiction) { $metadata["tax_jurisdiction"] = $TaxJurisdiction }
    if ($NoticeType) { $metadata["notice_type"] = $NoticeType }
    if ($EinTaxId) { $metadata["ein_tax_id"] = $EinTaxId }
    if ($TotalAmountDue) { $metadata["total_amount_due"] = $TotalAmountDue }
    if ($FilingDeadline) { $metadata["filing_deadline"] = $FilingDeadline }
    if ($NoticeNumber) { $metadata["notice_number"] = $NoticeNumber }
    if ($NoticeDate) { $metadata["notice_date"] = $NoticeDate }
    if ($TaxpayerAddress) { $metadata["taxpayer_address"] = $TaxpayerAddress }
    if ($TaxAuthorityAddress) { $metadata["tax_authority_address"] = $TaxAuthorityAddress }
    if ($TaxPeriod) { $metadata["tax_period"] = $TaxPeriod }
    if ($ActionNeeded) { $metadata["action_needed"] = $ActionNeeded }
    if ($EmailId) { $metadata["emailId"] = $EmailId }
    if ($MessageId) { $metadata["messageId"] = $MessageId }
    if ($Status) { $metadata["status"] = $Status }
    
    # Add system metadata
    $metadata["upload_date"] = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
    $metadata["uploaded_by"] = $env:USERNAME
    
    return $metadata
}

# Function to upload file with metadata
function Upload-FileWithMetadata {
    param(
        [string]$FilePath,
        [string]$ContainerName,
        [object]$StorageContext,
        [hashtable]$Metadata
    )
    
    try {
        $fileName = Split-Path $FilePath -Leaf
        
        Write-Host "Uploading file '$fileName' to container '$ContainerName'..." -ForegroundColor Yellow
        
        $blob = Set-AzStorageBlobContent -File $FilePath `
                                       -Container $ContainerName `
                                       -Blob $fileName `
                                       -Context $StorageContext `
                                       -Metadata $Metadata `
                                       -Force
        
        Write-Host "✓ File uploaded successfully!" -ForegroundColor Green
        Write-Host "Blob URL: $($blob.ICloudBlob.StorageUri.PrimaryUri)" -ForegroundColor Cyan
        
        return $blob
    }
    catch {
        Write-Error "Failed to upload file: $($_.Exception.Message)"
        exit 1
    }
}

# Function to display metadata
function Show-Metadata {
    param([hashtable]$Metadata)
    
    Write-Host "`nMetadata applied:" -ForegroundColor Yellow
    Write-Host "==================" -ForegroundColor Yellow
    
    foreach ($key in $Metadata.Keys | Sort-Object) {
        Write-Host "$key : $($Metadata[$key])" -ForegroundColor Cyan
    }
}

# Main execution
try {
    Write-Host "Azure Tax Document Upload Script" -ForegroundColor Magenta
    Write-Host "=================================" -ForegroundColor Magenta
    
    # Validate inputs
    Test-FileExists -Path $FilePath
    
    # Connect to Azure
    Connect-ToAzure
    
    # Get storage context
    $storageContext = Get-StorageContext -StorageAccountName $StorageAccountName -ResourceGroupName $ResourceGroupName
    
    # Create metadata
    $metadata = New-MetadataHashtable
    
    # Show what metadata will be applied
    Show-Metadata -Metadata $metadata
    
    # Upload file
    $uploadResult = Upload-FileWithMetadata -FilePath $FilePath `
                                          -ContainerName $ContainerName `
                                          -StorageContext $storageContext `
                                          -Metadata $metadata
    
    Write-Host "`n✓ Upload completed successfully!" -ForegroundColor Green
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    exit 1
}

# Example usage information
Write-Host "`nExample Usage:" -ForegroundColor Yellow
Write-Host ".\Upload-TaxDocument.ps1 -FilePath 'C:\temp\tax-notice.pdf' -TaxpayerName 'ABC Corp' -NoticeType 'Balance Due' -TotalAmountDue '5000.00'" -ForegroundColor Gray