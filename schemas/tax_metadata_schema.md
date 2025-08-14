# Tax Document Metadata Schema & Team Notification Framework

## 📊 Core Metadata Fields for Tax Records

### Document Identification
```json
{
  "documentId": "string (unique identifier)",
  "emailId": "string (source email reference)",
  "attachmentName": "string (original filename)",
  "sharepointUrl": "string (document library location)",
  "processedDate": "datetime (when AI processed)",
  "documentHash": "string (for duplicate detection)"
}
```

### Tax Authority Information
```json
{
  "taxAuthority": "string (IRS, State of NC, City of Charlotte)",
  "jurisdiction": "string (Federal, State, Local)",
  "contactAgency": "string (specific department/division)",
  "agencyAddress": "string (mailing address)",
  "contactPhone": "string (agency contact number)",
  "contactEmail": "string (if available)",
  "agencyWebsite": "string (for online payments/info)"
}
```

### Document Classification
```json
{
  "documentType": "string (Balance Due, Assessment, Penalty, etc.)",
  "taxType": "string (Income, Sales, Payroll, Property, etc.)",
  "noticeType": "string (CP14, Assessment, Audit Results)",
  "noticeNumber": "string (official reference number)",
  "formNumber": "string (941, 720, etc. if applicable)",
  "urgencyLevel": "string (Critical, High, Medium, Low)"
}
```

### Company/Taxpayer Information
```json
{
  "companyName": "string (legal entity name)",
  "companyAddress": "string (registered address)",
  "taxId": "string (EIN, SSN, State ID)",
  "accountNumber": "string (agency account reference)",
  "businessType": "string (Corporation, LLC, Partnership)",
  "industry": "string (NAICS code or description)"
}
```

### Financial Details
```json
{
  "totalAmountDue": "decimal (primary amount)",
  "originalTax": "decimal (base tax amount)",
  "penalties": "decimal (penalty charges)",
  "interest": "decimal (interest charges)",
  "previousBalance": "decimal (if continuing liability)",
  "currency": "string (USD default)"
}
```

### Critical Dates
```json
{
  "noticeDate": "date (when notice was issued)",
  "dueDate": "date (payment/response deadline)",
  "taxPeriod": "string (period covered - Q4 2024, 2024, etc.)",
  "assessmentDate": "date (when assessment was made)",
  "interestAccrualDate": "date (when interest starts/started)",
  "daysUntilDue": "integer (calculated urgency)"
}
```

### Required Actions
```json
{
  "primaryAction": "string (Pay, File Return, Respond, Appeal)",
  "actionDeadline": "date (when action must be completed)",
  "paymentRequired": "boolean",
  "responseRequired": "boolean",
  "filingRequired": "boolean",
  "documentsNeeded": "array (list of required supporting docs)"
}
```

### Processing Status
```json
{
  "status": "string (New, Under Review, Pending Payment, Resolved)",
  "assignedTo": "string (team member if assigned)",
  "priority": "string (based on amount + urgency)",
  "nextAction": "string (what needs to happen next)",
  "lastUpdated": "datetime",
  "workflowStage": "string (Receipt, Review, Action, Follow-up)"
}
```

### Payment Information
```json
{
  "paymentMethods": "array (Check, ACH, Credit Card, Online)",
  "paymentAddress": "string (where to send payment)",
  "onlinePaymentUrl": "string (if available)",
  "paymentInstructions": "string (special requirements)",
  "installmentAvailable": "boolean",
  "earlyPaymentDiscount": "boolean"
}
```

### Appeal/Response Options
```json
{
  "appealRights": "boolean",
  "appealDeadline": "date",
  "conferenceAvailable": "boolean",
  "protestOptions": "array (Formal, Informal)",
  "supportingDocsRequired": "array",
  "responseFormRequired": "string (form number if applicable)"
}
```

### Risk Assessment
```json
{
  "riskLevel": "string (High, Medium, Low)",
  "consequencesOfInaction": "array (Additional penalties, Interest, Collection)",
  "businessImpact": "string (Cash flow, Operations, Compliance)",
  "recommendedAction": "string (AI recommendation)"
}
```

## 📧 Tax Team Notification Templates

### 🚨 Critical Priority Notification
**Subject:** `🚨 URGENT: Tax Notice Requires Immediate Action - ${companyName} - ${totalAmountDue}`

```
CRITICAL TAX NOTICE RECEIVED - IMMEDIATE ACTION REQUIRED

Company: ${companyName}
Tax Authority: ${taxAuthority}
Notice Type: ${documentType}
Amount Due: ${totalAmountDue}
Due Date: ${dueDate} (${daysUntilDue} days remaining)

⚠️ URGENCY FACTORS:
• ${urgencyReasons}

📋 REQUIRED ACTIONS:
Primary Action: ${primaryAction}
Deadline: ${actionDeadline}
${paymentRequired ? '💰 Payment Required' : ''}
${responseRequired ? '📝 Written Response Required' : ''}

🎯 RECOMMENDED NEXT STEPS:
1. ${recommendedAction}
2. Review document in SharePoint: ${sharepointUrl}
3. ${paymentRequired ? 'Prepare payment authorization' : 'Prepare response documentation'}

📞 AGENCY CONTACT:
${contactAgency}
Phone: ${contactPhone}
Reference: ${noticeNumber}

Click here to: [Review Document] [Approve Payment] [Generate Response] [Assign to Team Member]
```

### ⚠️ High Priority Notification
**Subject:** `⚠️ High Priority Tax Notice - ${documentType} - ${companyName} - Due ${dueDate}`

```
HIGH PRIORITY TAX NOTICE RECEIVED

Company: ${companyName}
Tax Type: ${taxType}
Authority: ${taxAuthority}
Notice: ${noticeType} #${noticeNumber}
Amount: ${totalAmountDue}
Due Date: ${dueDate}

💼 SUMMARY:
${documentSummary}

🎯 ACTION OPTIONS:
□ Pay Full Amount (${totalAmountDue})
□ Request Payment Plan
□ File Appeal/Protest
□ Generate Response Letter

📊 BREAKDOWN:
• Original Tax: ${originalTax}
• Penalties: ${penalties}
• Interest: ${interest}

⏰ TIMELINE:
• Payment Due: ${dueDate}
• Appeal Deadline: ${appealDeadline}
• Interest Accrual: ${interestAccrualDate}

📄 Document Location: ${sharepointUrl}

Actions: [Review & Decide] [Approve Payment] [Draft Response] [Schedule Review]
```

### 📋 Standard Priority Notification
**Subject:** `📋 Tax Notice Received - ${taxType} - ${companyName} - Review Required`

```
TAX NOTICE RECEIVED - REVIEW REQUIRED

Company: ${companyName}
Tax Authority: ${taxAuthority}
Document Type: ${documentType}
Amount Due: ${totalAmountDue}
Review By: ${dueDate}

📋 DOCUMENT DETAILS:
• Tax Period: ${taxPeriod}
• Notice Number: ${noticeNumber}
• Tax Type: ${taxType}

💡 AI ANALYSIS:
• Risk Level: ${riskLevel}
• Recommended Action: ${recommendedAction}
• Business Impact: ${businessImpact}

📂 NEXT STEPS:
1. Review document details
2. Verify accuracy of assessment
3. Choose response strategy
4. Set payment/response timeline

Document: ${sharepointUrl}
Agency Contact: ${contactPhone}

Actions: [Review Document] [Schedule Payment] [Research Options] [Assign Reviewer]
```

### 🔔 Informational Notification
**Subject:** `🔔 Tax Document Filed - ${documentType} - ${companyName} - No Immediate Action`

```
TAX DOCUMENT RECEIVED AND FILED

Company: ${companyName}
Document: ${documentType}
Tax Authority: ${taxAuthority}
Status: Filed for Reference

📄 DOCUMENT INFO:
• Type: ${documentType}
• Period: ${taxPeriod}
• Reference: ${noticeNumber}
• Filed: ${processedDate}

ℹ️ This document has been automatically filed in SharePoint for your records.
${actionRequired ? 'Future action may be required - review recommended.' : 'No immediate action required.'}

Document Location: ${sharepointUrl}

Actions: [View Document] [Add to Calendar] [File for Later Review]
```

## 🎯 Decision Tree for Team Actions

### Payment Decision Flow
```
IF totalAmountDue > $10,000 OR urgencyLevel = "Critical"
  → Require Manager Approval
  → Generate payment authorization form
  → Set up approval workflow

IF appealRights = true AND daysUntilDue > 30
  → Present appeal option prominently
  → Provide appeal form template
  → Schedule legal review

IF paymentPlan available AND totalAmountDue > $5,000
  → Offer installment option
  → Calculate payment schedule
  → Present terms for approval
```

### Response Generation Options
```
Approve and Pay:
  → Generate payment letter
  → Process payment authorization
  → Send confirmation to agency
  → Update status to "Payment Sent"

Send to Payroll:
  → Forward to payroll team
  → Include calculation details
  → Set up recurring process if needed
  → Track payroll implementation

Generate Response:
  → Create draft response letter
  → Include supporting arguments
  → Attach relevant documentation
  → Route for legal review
```

## 📊 SharePoint Metadata Mapping

### Document Library Columns
- **Title**: ${documentType} - ${companyName} - ${noticeNumber}
- **Tax Authority**: ${taxAuthority}
- **Amount Due**: ${totalAmountDue}
- **Due Date**: ${dueDate}
- **Status**: ${status}
- **Priority**: ${urgencyLevel}
- **Assigned To**: ${assignedTo}
- **Tax Type**: ${taxType}
- **Company**: ${companyName}
- **Action Required**: ${primaryAction}

### Content Types
- **Tax Notice** (Balance due, assessments)
- **Tax Penalty** (Late payment, filing penalties)
- **Tax Correspondence** (General agency communication)
- **Tax Audit** (Examination results, requests)
- **Tax Filing** (Required submissions, returns)

This metadata schema ensures comprehensive tracking while the notification system provides clear, actionable information to the Tax Team for efficient decision-making.