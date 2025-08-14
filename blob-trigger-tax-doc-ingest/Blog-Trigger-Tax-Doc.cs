using Azure;
using Azure.Identity;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using blob_trigger_tax_doc_ingest.Services;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using System;
using System.IO;
using System.Net.Http;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;

namespace blob_trigger_tax_doc_ingest
{
    /// <summary>
    /// Azure Function triggered when a new blob is added to the "incoming" container.
    /// Processes tax document PDFs using Azure AI Content Understanding service to extract
    /// metadata fields, and updates the blob's metadata with the extracted information.
    /// </summary>
    public class Blog_Trigger_Tax_Doc
    {
        private readonly ILogger<Blog_Trigger_Tax_Doc> _logger;
        private readonly ContentUnderstandingService _contentService;
        private readonly BlobServiceClient _blobServiceClient;
        
        /// <summary>
        /// Maximum time (in seconds) to poll for Content Understanding job completion
        /// </summary>
        private const int MaxPollTimeoutSeconds = 30;
        
        /// <summary>
        /// Interval (in milliseconds) between consecutive polling attempts
        /// </summary>
        private const int PollIntervalMs = 2000; // 2 seconds between polls

        /// <summary>
        /// The name of the source container where new blobs are uploaded
        /// </summary>
        private const string SourceContainerName = "incoming";

        /// <summary>
        /// The name of the destination container where processed blobs are moved
        /// </summary>
        private const string DestinationContainerName = "processed";

        /// <summary>
        /// Initializes a new instance of the <see cref="Blog_Trigger_Tax_Doc"/> class.
        /// </summary>
        /// <param name="logger">The logger for writing diagnostic information</param>
        /// <param name="contentService">The service for communicating with Azure AI Content Understanding</param>
        /// <exception cref="InvalidOperationException">Thrown when StorageAccountName environment variable is not set</exception>
        public Blog_Trigger_Tax_Doc(ILogger<Blog_Trigger_Tax_Doc> logger, ContentUnderstandingService contentService)
        {
            _logger = logger;
            _contentService = contentService;

            var credential = new DefaultAzureCredential();
            var storageAccountName = Environment.GetEnvironmentVariable("StorageAccountName")
                ?? throw new InvalidOperationException("StorageAccountName environment variable is required");

            _blobServiceClient = new BlobServiceClient(
                new Uri($"https://{storageAccountName}.blob.core.windows.net/"),
                credential);
        }

        /// <summary>
        /// Processes a new blob added to the "incoming" container.
        /// 1. Reads existing blob metadata
        /// 2. Submits the document to Azure AI Content Understanding service
        /// 3. Polls for job completion with a timeout
        /// 4. Extracts metadata fields from the analysis results
        /// 5. Updates the blob's metadata with the extracted fields
        /// 6. Moves the blob to the "processed" container
        /// </summary>
        /// <param name="stream">The blob content stream</param>
        /// <param name="name">The name of the blob that triggered this function</param>
        /// <returns>A task representing the asynchronous operation</returns>
        [Function(nameof(Blog_Trigger_Tax_Doc))]
        public async Task Run([BlobTrigger("incoming/{name}", Connection = "StorageConnection")] Stream stream, string name)
        {
            var blobUrl = $"https://{Environment.GetEnvironmentVariable("StorageAccountName")}.blob.core.windows.net/{SourceContainerName}/{name}";
            var blobFileContext = new BlobFileContext
            {
                Name = name,
                Url = blobUrl
            };

            try
            {
                // Try to get blob metadata
                BlobClient sourceBlobClient;
                try
                {
                    var containerClient = _blobServiceClient.GetBlobContainerClient(SourceContainerName);
                    sourceBlobClient = containerClient.GetBlobClient(name);
                    var properties = await sourceBlobClient.GetPropertiesAsync();
                    var metadata = properties.Value.Metadata;

                    metadata.TryGetValue("MessageId", out var messageId);
                    metadata.TryGetValue("EmailId", out var emailId);
                    metadata.TryGetValue("Status", out var status);

                    blobFileContext.MessageId = messageId;
                    blobFileContext.EmailId = emailId;
                    blobFileContext.Status = status;

                    _logger.LogInformation($"Blob metadata - MessageId: {messageId}, EmailId: {emailId}, Status: {status}");
                }
                catch (RequestFailedException ex)
                {
                    _logger.LogError(ex, $"Failed to get properties for blob '{name}'.");
                    blobFileContext.Status = "BlobMetadataError";
                    return;
                }

                // Try to call Content Understanding API
                try
                {
                    var result = await _contentService.AnalyzeDocumentAsync(blobUrl);
                    _logger.LogInformation($"Operation-Location: {result.OperationLocation}");
                    _logger.LogInformation($"Response Body: {result.ResponseBody}");

                    if (string.IsNullOrEmpty(result.OperationLocation))
                    {
                        _logger.LogError($"Operation-Location is null or empty for blob '{name}'.");
                        blobFileContext.Status = "ContentUnderstandingApiError";
                        return;
                    }

                    // Poll for job completion with timeout
                    bool jobSucceeded = await PollForJobCompletionAsync(result.OperationLocation, name);
                    if (!jobSucceeded)
                    {
                        _logger.LogWarning($"Content Understanding job timed out or failed for blob '{name}'.");
                        blobFileContext.Status = "ContentUnderstandingTimeout";
                        return;
                    }
                    
                    // Get the final job status
                    var jobStatus = await _contentService.PollJobStatusAsync(result.OperationLocation);
                    _logger.LogInformation($"Final job status: {jobStatus}");
                    
                    // Extract fields and update metadata
                    bool success = await _contentService.ExtractFieldsAndUpdateMetadata(jobStatus, sourceBlobClient, blobFileContext);
                    if (success)
                    {
                        _logger.LogInformation($"Successfully extracted fields and updated metadata for blob: {name}");
                        
                        // Move the blob to the processed container
                        await MoveToProcessedContainerAsync(sourceBlobClient, name);
                    }
                    else
                    {
                        _logger.LogWarning($"Failed to extract fields or update metadata for blob: {name}");
                        blobFileContext.Status = "ProcessingFailed";
                    }
                }
                catch (HttpRequestException ex)
                {
                    _logger.LogError(ex, $"HTTP error calling Content Understanding API for blob '{name}': {ex.Message}");
                    blobFileContext.Status = "ContentUnderstandingApiError";
                    return;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Unexpected error processing blob '{name}': {ex.Message}");
                blobFileContext.Status = "UnexpectedError";
            }
        }

        /// <summary>
        /// Polls the Content Understanding job until it completes or times out.
        /// Periodically checks the job status and returns when the job succeeds, fails, or times out.
        /// </summary>
        /// <param name="operationLocation">The operation location URL returned from the API</param>
        /// <param name="blobName">The name of the blob being processed (for logging purposes)</param>
        /// <returns>
        /// <c>true</c> if the job completed successfully with "Succeeded" status;
        /// <c>false</c> if the job failed, was canceled, or timed out
        /// </returns>
        private async Task<bool> PollForJobCompletionAsync(string operationLocation, string blobName)
        {
            _logger.LogInformation($"Starting polling for job completion for blob '{blobName}'.");
            
            DateTime startTime = DateTime.UtcNow;
            DateTime timeoutTime = startTime.AddSeconds(MaxPollTimeoutSeconds);

            while (DateTime.UtcNow < timeoutTime)
            {
                try
                {
                    var jobStatusJson = await _contentService.PollJobStatusAsync(operationLocation);
                    
                    using var jobStatusDoc = JsonDocument.Parse(jobStatusJson);
                    var status = jobStatusDoc.RootElement.GetProperty("status").GetString();
                    
                    _logger.LogInformation($"Job status: {status} for blob '{blobName}'");
                    
                    if (status == "Succeeded")
                    {
                        return true;
                    }
                    else if (status == "Failed" || status == "Canceled")
                    {
                        _logger.LogWarning($"Job {status} for blob '{blobName}'");
                        return false;
                    }
                    
                    // Wait before polling again
                    await Task.Delay(PollIntervalMs);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, $"Error polling job status for blob '{blobName}'");
                    return false;
                }
            }
            
            _logger.LogWarning($"Job polling timed out after {MaxPollTimeoutSeconds} seconds for blob '{blobName}'");
            return false;
        }

        /// <summary>
        /// Moves a blob from the source container to the processed container, preserving all metadata.
        /// </summary>
        /// <param name="sourceBlobClient">The source blob client</param>
        /// <param name="blobName">The name of the blob</param>
        /// <returns>A task representing the asynchronous operation</returns>
        private async Task MoveToProcessedContainerAsync(BlobClient sourceBlobClient, string blobName)
        {
            try
            {
                _logger.LogInformation($"Moving blob '{blobName}' to {DestinationContainerName} container");
                
                // Ensure the destination container exists
                var destinationContainerClient = _blobServiceClient.GetBlobContainerClient(DestinationContainerName);
                await destinationContainerClient.CreateIfNotExistsAsync();

                // Get a reference to the destination blob
                var destinationBlobClient = destinationContainerClient.GetBlobClient(blobName);

                // Get source blob properties to copy metadata
                var sourceProperties = await sourceBlobClient.GetPropertiesAsync();

                // Start copy operation from source to destination
                var copyOperation = await destinationBlobClient.StartCopyFromUriAsync(sourceBlobClient.Uri);

                // Wait for the copy operation to complete
                await WaitForCopyToCompleteAsync(destinationBlobClient, blobName);

                // Delete the source blob
                await sourceBlobClient.DeleteAsync();

                _logger.LogInformation($"Successfully moved blob '{blobName}' to {DestinationContainerName} container");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to move blob '{blobName}' to {DestinationContainerName} container");
                throw; // Re-throw to ensure the error is handled by the calling code
            }
        }

        /// <summary>
        /// Waits for a blob copy operation to complete
        /// </summary>
        /// <param name="destinationBlobClient">The destination blob client</param>
        /// <param name="blobName">The name of the blob (for logging)</param>
        /// <returns>A task representing the asynchronous operation</returns>
        private async Task WaitForCopyToCompleteAsync(BlobClient destinationBlobClient, string blobName)
        {
            // Check copy status
            BlobProperties properties = await destinationBlobClient.GetPropertiesAsync();
            
            // Maximum wait time for copy to complete (30 seconds)
            DateTime timeoutTime = DateTime.UtcNow.AddSeconds(30);
            
            while (properties.CopyStatus == CopyStatus.Pending && DateTime.UtcNow < timeoutTime)
            {
                // Wait before checking again
                await Task.Delay(1000);
                properties = await destinationBlobClient.GetPropertiesAsync();
            }

            // Verify copy completed successfully
            if (properties.CopyStatus != CopyStatus.Success)
            {
                _logger.LogError($"Copy operation for blob '{blobName}' did not complete successfully. Status: {properties.CopyStatus}");
                throw new InvalidOperationException($"Copy operation for blob '{blobName}' failed with status: {properties.CopyStatus}");
            }
            
            _logger.LogInformation($"Copy operation completed for blob '{blobName}'");
        }
    }
}
