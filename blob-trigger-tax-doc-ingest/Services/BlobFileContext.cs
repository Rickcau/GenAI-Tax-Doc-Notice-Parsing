namespace blob_trigger_tax_doc_ingest.Services
{
    public class BlobFileContext
    {
        public string Name { get; set; } = string.Empty;
        public string Url { get; set; } = string.Empty;

        // Metadata properties
        public string? MessageId { get; set; }
        public string? EmailId { get; set; }
        public string? Status { get; set; }
        public string? TaxpayerName { get; set; }
        public string? TaxJurisdiction { get; set; }
        public string? NoticeType { get; set; }
        public string? EinTaxId { get; set; }
        public string? TotalAmountDue { get; set; }
        public string? FilingDeadline { get; set; }
        public string? NoticeNumber { get; set; }
        public string? NoticeDate { get; set; }
        public string? TaxpayerAddress { get; set; }
        public string? TaxAuthorityAddress { get; set; }
        public string? TaxPeriod { get; set; }
        public string? ActionNeeded { get; set; }
        
        // New metadata properties
        public string? PaymentInstructions { get; set; }
        public string? PaymentInterestBreakdown { get; set; }
        public string? AssessmentCodeOrFormNumber { get; set; }
        public string? TaxAuthority { get; set; }
        public string? DisputeOrAppealDeadline { get; set; }
        public string? PaymentCouponRemittanceSlip { get; set; }

        // Additional metadata properties
        public string? Description { get; set; }
        public string? EinTaxIdNotes { get; set; }
        public string? EmployeeIdNumber { get; set; }
        public string? ContactPhoneNumber { get; set; }
        public string? ContactFaxNumber { get; set; }
        public string? ContactEmailAddress { get; set; }
    }
}