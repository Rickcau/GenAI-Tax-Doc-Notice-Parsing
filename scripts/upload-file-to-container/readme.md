# Tax Document Upload Script

A PowerShell script for uploading tax documents to Azure Blob Storage with rich metadata to support automated document processing workflows.

## Overview

The `Upload-TaxDocument.ps1` script simplifies the process of uploading tax-related documents to Azure Blob Storage while attaching comprehensive metadata that can be used by downstream processes like Azure Functions, Logic Apps, or AI Content Understanding services. This script is part of the larger tax document processing solution.

## Prerequisites

- PowerShell 5.1 or higher
- Azure PowerShell modules installed (`Az.Accounts` and `Az.Storage`)
- Access to an Azure subscription
- Azure Storage account information (name and resource group)
- Tax documents you want to upload

## Installation

If you don't have the Azure PowerShell modules installed, run:

    ```powershell
        # Install the Azure PowerShell module (if not already installed)
        Install-Module -Name Az -Force -AllowClobber -Scope CurrentUser

        # Import the module
        Import-Module Az

        # Specifically import the Storage module
        Import-Module Az.Storage
    ```

## Basic Useage

   ```
      .\Upload-TaxDocument.ps1 -FilePath "..\..\docs\tax-docs\tax_notice_business_license_1754332187471.pdf" ` 
      -EmailId "user@company.com" ` 
      -Status "pending" ` 
      -MessageId "12345"
   ```

   ** Command for the V2 which is working as of 8/12/2025 **
   ```
        .\upload-file-v2.ps1 -FilePath "..\..\docs\tax-docs\tax_notice_business_license_1754332187471.pdf" -EmailId "steve@nctax.gov" -MessageId "12345"

        .\upload-file-v2.ps1 -FilePath "..\..\docs\tax-docs-customer\IMG_2525.jpg" -EmailId "steve2@nctax.gov" -MessageId "123456"
   ```

This uploads the document to the default container with minimal metadata.

## Parameters
**Required Parameters**
- **FilePath**: Path to the local file you want to upload.

### Storage Parameters
StorageAccountName: Name of the Azure Storage account (default: "stgcdmtaxdocswest")
- **ContainerName**: Name of the blob container (default: "incoming")
- **ResourceGroupName**: Name of the resource group containing the storage account

### Tax Document Metadata Parameters
All metadata parameters are optional but at a minimum you need to set **Status** to "uploaded", and EmailId to the email address that this document is assoicated with, and the MessageId which is the unique MessageId from the Exchange Server.  For testing you can just make something up.  Ideally, you would be using PowerAutomate to Monitor a MailBox for emails and when it has an attachment, copy the attachment to the Storage container with the **Status**, **EmailId** and **MessageId** set.

**Important Note**
All the metadata properties exclusing **Status**, **EmailId** and **MessageId** will be set by the Tax Processing Document logic using Azure AI Content Understanding. The idea is that when the files are being pushed to Azure Storage Container `\incoming` that you set the **Status**, **EmailId** and **MessageId** and as the documents are being processed the other properties will be updated.

- **TaxpayerName**: Name of the taxpayer or business
- **TaxJurisdiction**: Tax authority jurisdiction (e.g., "IRS", "California FTB")
- **NoticeType:** Type of tax notice (e.g., "Balance Due", "Refund Notice")
- **EinTaxId**: Employer Identification Number or Tax ID
- **TotalAmountDue**: Total amount due on the notice
- **FilingDeadline**: Deadline date for filing or payment
- **NoticeNumber**: Reference number on the tax notice
- **NoticeDate**: Date on the tax notice
- **TaxpayerAddress:** Taxpayer's address from the document
- **TaxAuthorityAddress**: Tax authority's address from the document
- **TaxPeriod**: Tax period covered by the notice
- **ActionNeeded**: Description of required action (e.g., "Payment", "Response")
- **EmailId**: ID of the email where this document was received
- **MessageId**: ID of the message containing this document
- **Status**: Processing status (default: "pending")

##

