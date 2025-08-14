# internal_readme.md
This readme is for local use only and has been added to the .gitignore file so it's not uploaded to the GitHub Repo for security reasons.  It's just used for local testing.

## 1. Use Curl to create a new or update an existing Analyzer
The following Curl command can be used in a Windows Terminal Window to create a customer analyzer.

1. Navigate to the **schemas** folder in the Terminal window and use the following Curl command to just point to the local schema file.  

   ```
        curl -i -X PUT "https://rdc-cdm-smith-tax-doc-resource.cognitiveservices.azure.com/contentunderstanding/analyzers/Simple-Tax-Analyzer?api-version=2025-05-01-preview&stringEncoding=utf16&enableJailbreakDetection=false" -H "Ocp-Apim-Subscription-Key:6dUm2iA5ciDQIsbj3TJxhC60Z3J9TEDp87nRoMeDLDoxWMm2qQj1JQQJ99BHAC4f1cMXJ3w3AAAAACOGzWBp" -H "Content-Type: application/json" -H "x-ms-useragent: cu-sample-code" --data @Tax-Doc-Analyer-Simple-Schema.json
   ```

## ## 2. Use Curl to test the parasing of a file in an Azure Storage Account
The following Curl command can be used in a Windows Terminal window.  This command is intended to be used after you create the custom analyzer with the custom fields to parse the documents.

   ```
        curl -i -X POST "https://rdc-cdm-smith-tax-doc-resource.cognitiveservices.azure.com/contentunderstanding/analyzers/Simple-Tax-Analyzer:analyze?api-version=2025-05-01-preview&stringEncoding=utf16&enableJailbreakDetection=false" `
        -H "Ocp-Apim-Subscription-Key:6dUm2iA5ciDQIsbj3TJxhC60Z3J9TEDp87nRoMeDLDoxWMm2qQj1JQQJ99BHAC4f1cMXJ3w3AAAAACOGzWBp" `
        -H "Content-Type: application/json" `
        -H "x-ms-useragent: cu-sample-code" `
        -d '{"url":"https://stgcdmtaxdocswest.blob.core.windows.net/incoming/tax_notice_business_license_1754332187471.pdf"}'

   ```

   If the POST was submitting successfully, you will get a response that looks like the following:

   [Custom-Analyzer-Response](../../images/custom-analyzer-response.jpg)

## 3. Use Curl to poll for the status of the job
Once you receive the response from the POST request to analyze the Tax Document, you will need to store the value of the `Operation-Location` so you can poll for the status of the job.  Below is an example of a **Curl** command you can use for this.

You need to replace the URL with the `Operation-Location` you got in the reponse from the file you processed above.

   ```
        curl -i -X GET "https://rdc-cdm-smith-tax-doc-resource.cognitiveservices.azure.com/contentunderstanding/analyzerResults/bd4ec518-8171-4a95-9300-8421af7f0e54?api-version=2025-05-01-preview" -H "Ocp-Apim-Subscription-Key:6dUm2iA5ciDQIsbj3TJxhC60Z3J9TEDp87nRoMeDLDoxWMm2qQj1JQQJ99BHAC4f1cMXJ3w3AAAAACOGzWBp" -H "Content-Type: application/json" -H "x-ms-useragent: cu-sample-code"
   ```

## 4. Use Curl to list all Analyzers for Content Understanding
The Curl command below will list all Analyzers inlcude the Analyzers you have created with a custom schema.  If you want to filter out all the prebuilt analyzers you can write a PowerShell script to do so and just parse the JSON response and filter out the prebuilt ones.

   ```
      # List all your custom analyzers - Windows Command Prompt
        curl -i -X GET "https://rdc-cdm-smith-tax-doc-resource.cognitiveservices.azure.com/contentunderstanding/analyzers?api-version=2025-05-01-preview" -H "Ocp-Apim-Subscription-Key:6dUm2iA5ciDQIsbj3TJxhC60Z3J9TEDp87nRoMeDLDoxWMm2qQj1JQQJ99BHAC4f1cMXJ3w3AAAAACOGzWBp" -H "x-ms-useragent: cu-sample-code"
   ```

## 5. Use Curl to delete the custom Analyzer from Content Understanding

   ```
       # Delete your existing analyzer - Windows Command Prompt
        curl -i -X DELETE "https://rdc-cdm-smith-tax-doc-resource.cognitiveservices.azure.com/contentunderstanding/analyzers/CDM-Smith-Tax-Analyzer?api-version=2025-05-01-preview" -H "Ocp-Apim-Subscription-Key:6dUm2iA5ciDQIsbj3TJxhC60Z3J9TEDp87nRoMeDLDoxWMm2qQj1JQQJ99BHAC4f1cMXJ3w3AAAAACOGzWBp" -H "x-ms-useragent: cu-sample-code"
   ```

   `

   ```
```
    # Curl command to update a schema
    curl -i -X PUT "https://rdc-cdm-smith-tax-doc-resource.cognitiveservices.azure.com/contentunderstanding/analyzers/CDM-Smith-Tax-Analyzer?api-version=2025-05-01-preview" -H "Ocp-Apim-Subscription-Key:6dUm2iA5ciDQIsbj3TJxhC60Z3J9TEDp87nRoMeDLDoxWMm2qQj1JQQJ99BHAC4f1cMXJ3w3AAAAACOGzWBp" -H "Content-Type: application/json" -H "x-ms-useragent: cu-sample-code" -d "{\"description\":\"Simplified Tax Document Analyzer - 2 Fields Only\",\"baseAnalyzerId\":\"prebuilt-documentAnalyzer\",\"config\":{\"returnDetails\":false,\"estimateFieldSourceAndConfidence\":false,\"enableOcr\":true,\"enableLayout\":true,\"enableFormula\":false,\"disableContentFiltering\":false,\"tableFormat\":\"html\"},\"fieldSchema\":{\"fields\":{\"taxpayer_name\":{\"type\":\"string\",\"method\":\"extract\",\"description\":\"Extract the primary taxpayer's full name or business entity name\"},\"tax_jurisdiction\":{\"type\":\"string\",\"method\":\"extract\",\"description\":\"The governmental authority responsible for the tax\"}}}}"
   ```