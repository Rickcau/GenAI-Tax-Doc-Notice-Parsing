# GENAI-TAX-DOC-NOTICE-PARSING

A comprehensive Azure-based solution for automating the receipt, processing, and routing of tax documents using Logic Apps Standard, Azure AI Content Understanding, and Microsoft 365 integration.

# IMPORTANT NOTE #
I have not started build any logic apps for this yet.

## 🎯 Solution Overview

This solution automates the entire tax document workflow:
1. **Email Monitoring** - Monitors shared mailbox for tax-related attachments
2. **Document Classification** - Uses AI to identify and classify tax documents
3. **Metadata Extraction** - Extracts key information (amounts, due dates, authorities)
4. **Intelligent Routing** - Routes documents based on type, urgency, and business rules
5. **Team Notifications** - Alerts tax team with actionable information
6. **Approval Workflows** - Manages approval processes for high-value items
7. **Response Generation** - Creates appropriate responses to tax authorities

## 📁 Project Structure

```
GENAI-TAX-DOC-NOTICE-PARSING/        (root/workspace)
├── blob-trigger-tax-doc-ingest/     (container for Azure Function Blob Trigger)
│   ├── Functions/                   (container for all Azure Function logic)
│   ├── Models/                      (container for all Models)
│   ├── Services/                    (container for all Services)
│   │   └── BlobFileContext.cs
│   │   └── ContentUnderstandingResult.cs
│   │   └── ContentUnderstandingService.cs
│   ├── Utils/                       (container for all Utility related classes)
│   ├── Blob-Trigger-Tax-Doc.cs      (Azure Function - Entry point for Blob Trigger)
│   ├── host.json   
│   ├── Program.cs                   (Startup program for the Azure Function)
│   └── local.settings.example.json. (example local.settings.json file)
├── logic-apps/                   (container for all Logic App workflows)
│   ├── EmailMonitoring/        (monitors mailbox for tax documents)
│   │   └── workflow.json
│   ├── NotifyTeam/             (notifies tax team via Microsoft Teams that action needs to be taken)
│   │   └── workflow.json
├── api/                        (REST APIs)
├── ui/                         (Frontend application)
└── docs/                       (Documentation)
```

## 🏗️ Architecture

### Two-Workflow Design
- **Workflow 1**: Email Monitor (Stateful Logic App) - Permanent, handles email processing
- **Workflow 2**: Document Processor (Agent Workflow) - Evolves from basic to AI-enhanced

### Technology Stack
- **Azure Logic Apps Standard** - Workflow orchestration
- **Azure AI Content Understanding** - Document analysis and classification
- **Microsoft 365** - Email, Teams, SharePoint integration
- **Microsoft Dataverse** - Structured data storage
- **Power Platform** - Approval workflows and dashboards

##  Workflows Description

### Workflow 1: EmailMonitoring
**Purpose**: Email Processing and Attachment Extraction
- **Type**: Stateful Logic App
- **Trigger**: Office 365 "When a new email arrives"
- **Responsibilities**:
  - Monitor shared mailbox (`taxdocuments@company.com`)
  - Extract PDF attachments from emails
  - Upload attachments to Azure Blob Storage
  - Send notifications for emails without attachments
  - Trigger downstream document processing

## Development

1. Open the `.code-workspace` file in VS Code
2. Use the Azure Logic Apps extension to work with the workflows
3. You can add additional workflows in the `logic-apps` folder

## Adding a New Workflow

To add a new workflow to the Logic App project:

1. Create a new folder in the `logic-apps` directory
2. Create a workflow.json file in that folder
3. Use the Azure Logic Apps extension to design the workflow

The workflows will share the same `host.json` and `local.settings.json` files.

## Future Components

- **REST APIs**: Will be developed in the `api` folder
- **UI**: Will be developed in the `ui` folder
- **Documentation**: Will be maintained in the `docs` folder

---

**Last Updated**: August 4, 2025
