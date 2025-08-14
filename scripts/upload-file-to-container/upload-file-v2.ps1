# Simple Azure Blob Upload Script with Tax Document Metadata
# Update: Working as of 8/12/2025
param(
    [Parameter(Mandatory=$true)]
    [string]$FilePath,
    
    [Parameter(Mandatory=$false)]
    [string]$StorageAccountName = "stgcdmtaxdocswest",
    
    [Parameter(Mandatory=$false)]
    [string]$ContainerName = "incoming",
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "rg-cdm-smith-west",  # UPDATE THIS
    
    # Tax Document Metadata Parameters
    [string]$TaxpayerName = "",
    [string]$TaxJurisdiction = "",
    [string]$NoticeType = "",
    [string]$EinTaxId = "",
    [string]$TotalAmountDue = "",
    [string]$FilingDeadline = "",
    [string]$NoticeNumber = "",
    [string]$NoticeDate = "",
    [string]$TaxpayerAddress = "",
    [string]$TaxAuthorityAddress = "",
    [string]$TaxPeriod = "",
    [string]$ActionNeeded = "",
    [string]$EmailId = "",
    [string]$MessageId = "",
    [string]$Status = "pending"
)

Write-Host "Azure Tax Document Upload Script" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green

# Import required modules
Write-Host "Loading Azure modules..." -ForegroundColor Yellow
try {
    Import-Module Az.Accounts -Force
    Import-Module Az.Storage -Force
    Write-Host "✓ Modules loaded successfully" -ForegroundColor Green
}
catch {
    Write-Error "Failed to load Azure modules. Please run: Install-Module -Name Az -Force"
    exit 1
}

# Resolve file path (handle relative paths)
if (-not [System.IO.Path]::IsPathRooted($FilePath)) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $FilePath = Join-Path $scriptDir $FilePath
    $FilePath = [System.IO.Path]::GetFullPath($FilePath)
}

# Check if file exists
if (-not (Test-Path $FilePath)) {
    Write-Error "File not found: $FilePath"
    exit 1
}
Write-Host "✓ File found: $FilePath" -ForegroundColor Green

# Connect to Azure
Write-Host "Checking Azure connection..." -ForegroundColor Yellow
try {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Yellow
        Connect-AzAccount
    } else {
        Write-Host "✓ Connected as: $($context.Account.Id)" -ForegroundColor Green
    }
}
catch {
    Write-Error "Failed to connect to Azure: $($_.Exception.Message)"
    exit 1
}

# Get storage account context
Write-Host "Getting storage account context..." -ForegroundColor Yellow
try {
    $storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
    $ctx = $storageAccount.Context
    Write-Host "✓ Storage account context obtained" -ForegroundColor Green
}
catch {
    Write-Error "Failed to get storage account. Please check ResourceGroupName and StorageAccountName."
    Write-Host "Current values: RG='$ResourceGroupName', Storage='$StorageAccountName'" -ForegroundColor Red
    exit 1
}

# Create metadata hashtable
$metadata = @{}

# Add metadata only if values are provided
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

# Display metadata
if ($metadata.Count -gt 0) {
    Write-Host "`nMetadata to be applied:" -ForegroundColor Yellow
    foreach ($key in $metadata.Keys | Sort-Object) {
        Write-Host "  $key = $($metadata[$key])" -ForegroundColor Cyan
    }
}

# Upload file
$fileName = Split-Path $FilePath -Leaf
Write-Host "`nUploading '$fileName' to container '$ContainerName'..." -ForegroundColor Yellow

try {
    $blob = Set-AzStorageBlobContent -File $FilePath `
                                   -Container $ContainerName `
                                   -Blob $fileName `
                                   -Context $ctx `
                                   -Metadata $metadata `
                                   -Force
    
    Write-Host "✓ Upload successful!" -ForegroundColor Green
    Write-Host "Blob URL: $($blob.ICloudBlob.StorageUri.PrimaryUri)" -ForegroundColor Cyan
}
catch {
    Write-Error "Upload failed: $($_.Exception.Message)"
    exit 1
}

Write-Host "`n✓ Script completed successfully!" -ForegroundColor Green