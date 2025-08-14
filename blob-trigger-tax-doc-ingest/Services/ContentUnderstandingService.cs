using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Azure.Storage.Blobs; // Add this for BlobClient
using System.Collections.Generic; // Add this for Dictionary<TKey,TValue>

namespace blob_trigger_tax_doc_ingest.Services
{
    public class ContentUnderstandingService
    {
        private readonly HttpClient _httpClient;
        private readonly string _endpoint;
        private readonly string _apiKey;

        public ContentUnderstandingService(HttpClient httpClient, IConfiguration configuration)
        {
            _httpClient = httpClient;
            _endpoint = configuration["ContentUnderstanding:Endpoint"] ?? "";
            _apiKey = configuration["ContentUnderstanding:ApiKey"] ?? "";
        }

        public async Task<ContentUnderstandingResult> AnalyzeDocumentAsync(string blobUrl)
        {
            var requestUri = $"{_endpoint}?api-version=2025-05-01-preview&stringEncoding=utf16&enableJailbreakDetection=false";
            var requestBody = JsonSerializer.Serialize(new { url = blobUrl });

            using var request = new HttpRequestMessage(HttpMethod.Post, requestUri);
            request.Headers.Add("Ocp-Apim-Subscription-Key", _apiKey);
            request.Headers.Add("x-ms-useragent", "cu-sample-code");
            request.Content = new StringContent(requestBody, Encoding.UTF8, "application/json");

            using var response = await _httpClient.SendAsync(request);
            response.EnsureSuccessStatusCode();

            // Get Operation-Location header
            string? operationLocation = response.Headers.TryGetValues("Operation-Location", out var values)
                ? values.FirstOrDefault()
                : null;

            string responseBody = await response.Content.ReadAsStringAsync();

            return new ContentUnderstandingResult
            {
                OperationLocation = operationLocation,
                ResponseBody = responseBody
            };

            // return await response.Content.ReadAsStringAsync();
        }

        public async Task<string> PollJobStatusAsync(string operationLocation)
        {
            // Append api-version if not present
            var uriBuilder = new UriBuilder(operationLocation);
            var query = System.Web.HttpUtility.ParseQueryString(uriBuilder.Query);
            if (string.IsNullOrEmpty(query["api-version"]))
                query["api-version"] = "2025-05-01-preview";
            uriBuilder.Query = query.ToString();
            var requestUri = uriBuilder.ToString();

            using var request = new HttpRequestMessage(HttpMethod.Get, requestUri);
            request.Headers.Add("Ocp-Apim-Subscription-Key", _apiKey);
            request.Headers.Add("x-ms-useragent", "cu-sample-code");
            request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));

            using var response = await _httpClient.SendAsync(request);
            response.EnsureSuccessStatusCode();

            return await response.Content.ReadAsStringAsync();
        }

        /// <summary>
        /// Extracts field values from a Content Understanding API job status response and updates blob metadata
        /// </summary>
        /// <param name="jobStatus">JSON response from the job status endpoint</param>
        /// <param name="blobClient">The BlobClient for the file to update</param>
        /// <param name="blobFileContext">Object to update with the extracted field values</param>
        /// <returns>True if successful, false otherwise</returns>
        public async Task<bool> ExtractFieldsAndUpdateMetadata(string jobStatus, BlobClient blobClient, BlobFileContext blobFileContext)
        {
            using var jobStatusJson = JsonDocument.Parse(jobStatus);
            var rootElement = jobStatusJson.RootElement;

            // Check if the job completed successfully
            if (!rootElement.TryGetProperty("status", out var statusElement) || 
                statusElement.GetString() != "Succeeded")
            {
                return false;
            }

            try
            {
                // Navigate to the fields object
                var fields = rootElement
                    .GetProperty("result")
                    .GetProperty("contents")[0]
                    .GetProperty("fields");

                // Update the BlobFileContext with extracted values
                blobFileContext.TaxpayerName = GetStringValue(fields, "taxpayer_name");
                blobFileContext.TaxJurisdiction = GetStringValue(fields, "tax_jurisdiction");
                blobFileContext.NoticeType = GetStringValue(fields, "notice_type");
                blobFileContext.EinTaxId = GetStringValue(fields, "ein_tax_id");
                blobFileContext.TotalAmountDue = GetNumberValue(fields, "total_amount_due");
                blobFileContext.FilingDeadline = GetDateValue(fields, "filing_deadline");
                blobFileContext.NoticeNumber = GetStringValue(fields, "notice_number");
                blobFileContext.NoticeDate = GetDateValue(fields, "notice_date");
                blobFileContext.TaxpayerAddress = GetStringValue(fields, "taxpayer_address");
                blobFileContext.TaxAuthorityAddress = GetStringValue(fields, "tax_authority_address");
                blobFileContext.TaxPeriod = GetStringValue(fields, "tax_period");
                blobFileContext.ActionNeeded = GetStringValue(fields, "action_needed");
                
                // Extract new fields
                blobFileContext.PaymentInstructions = GetStringValue(fields, "payment_instructions");
                blobFileContext.PaymentInterestBreakdown = GetStringValue(fields, "payment_interest_breakdown");
                blobFileContext.AssessmentCodeOrFormNumber = GetStringValue(fields, "assessment_code_or_form_number");
                blobFileContext.TaxAuthority = GetStringValue(fields, "tax_authority");
                blobFileContext.DisputeOrAppealDeadline = GetDateValue(fields, "dispute_or_appeal_deadline");
                blobFileContext.PaymentCouponRemittanceSlip = GetBooleanValue(fields, "payment_coupon_remittance_slip");
                
                // Extract additional fields
                blobFileContext.Description = GetStringValue(fields, "description");
                blobFileContext.EinTaxIdNotes = GetStringValue(fields, "ein_tax_id_notes");
                blobFileContext.EmployeeIdNumber = GetNumberValue(fields, "employee_id_number");
                blobFileContext.ContactPhoneNumber = GetStringValue(fields, "contact_phone_number");
                blobFileContext.ContactFaxNumber = GetStringValue(fields, "contact_fax_number");
                blobFileContext.ContactEmailAddress = GetStringValue(fields, "contact_email_address");

                // Create metadata dictionary from the BlobFileContext
                var updatedMetadata = new Dictionary<string, string>
                {
                    { "MessageId", blobFileContext.MessageId ?? "" },
                    { "EmailId", blobFileContext.EmailId ?? "" },
                    { "Status", "Processed" },
                    { "TaxpayerName", blobFileContext.TaxpayerName ?? "" },
                    { "TaxJurisdiction", blobFileContext.TaxJurisdiction ?? "" },
                    { "NoticeType", blobFileContext.NoticeType ?? "" },
                    { "EinTaxId", blobFileContext.EinTaxId ?? "" },
                    { "TotalAmountDue", blobFileContext.TotalAmountDue ?? "" },
                    { "FilingDeadline", blobFileContext.FilingDeadline ?? "" },
                    { "NoticeNumber", blobFileContext.NoticeNumber ?? "" },
                    { "NoticeDate", blobFileContext.NoticeDate ?? "" },
                    { "TaxpayerAddress", blobFileContext.TaxpayerAddress ?? "" },
                    { "TaxAuthorityAddress", blobFileContext.TaxAuthorityAddress ?? "" },
                    { "TaxPeriod", blobFileContext.TaxPeriod ?? "" },
                    { "ActionNeeded", blobFileContext.ActionNeeded ?? "" },
                    
                    // Add new metadata
                    { "PaymentInstructions", blobFileContext.PaymentInstructions ?? "" },
                    { "PaymentInterestBreakdown", blobFileContext.PaymentInterestBreakdown ?? "" },
                    { "AssessmentCodeOrFormNumber", blobFileContext.AssessmentCodeOrFormNumber ?? "" },
                    { "TaxAuthority", blobFileContext.TaxAuthority ?? "" },
                    { "DisputeOrAppealDeadline", blobFileContext.DisputeOrAppealDeadline ?? "" },
                    { "PaymentCouponRemittanceSlip", blobFileContext.PaymentCouponRemittanceSlip ?? "" },
                    
                    // Add additional metadata
                    { "Description", blobFileContext.Description ?? "" },
                    { "EinTaxIdNotes", blobFileContext.EinTaxIdNotes ?? "" },
                    { "EmployeeIdNumber", blobFileContext.EmployeeIdNumber ?? "" },
                    { "ContactPhoneNumber", blobFileContext.ContactPhoneNumber ?? "" },
                    { "ContactFaxNumber", blobFileContext.ContactFaxNumber ?? "" },
                    { "ContactEmailAddress", blobFileContext.ContactEmailAddress ?? "" }
                };
                
                // Set the metadata
                await blobClient.SetMetadataAsync(updatedMetadata);
                return true;
            }
            catch
            {
                return false;
            }
        }

        // Helper methods for value extraction
        private string GetStringValue(JsonElement element, string propertyName)
        {
            if (element.TryGetProperty(propertyName, out var prop) && 
                prop.TryGetProperty("valueString", out var value))
            {
                return value.GetString() ?? "";
            }
            return "";
        }

        private string GetNumberValue(JsonElement element, string propertyName)
        {
            if (element.TryGetProperty(propertyName, out var prop) && 
                prop.TryGetProperty("valueNumber", out var value))
            {
                return value.GetDouble().ToString();
            }
            return "";
        }

        private string GetDateValue(JsonElement element, string propertyName)
        {
            if (element.TryGetProperty(propertyName, out var prop) && 
                prop.TryGetProperty("valueDate", out var value))
            {
                return value.GetString() ?? "";
            }
            return "";
        }

        private string GetBooleanValue(JsonElement element, string propertyName)
        {
            if (element.TryGetProperty(propertyName, out var prop) && 
                prop.TryGetProperty("valueBoolean", out var value))
            {
                return value.GetBoolean().ToString();
            }
            return "";
        }
    }
}