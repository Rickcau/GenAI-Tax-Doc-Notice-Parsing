# Example Curl commands
You can use these commands to test out custom Tax Document Analyzer you created in Document Content Understanding.

## Use Curl to create a custom Analyzer
The following Curl command can be used in a Windows Terminal Window to create a customer analyzer.

1. Navigate to the **schemas** folder in the Terminal window and use the following Curl command to just point to the local schema file.

   ```
        curl -i -X PUT "https://YOUR_RESOURCE_HERE.cognitiveservices.azure.com/contentunderstanding/analyzers/Simple-Tax-Analyzer?api-version=2025-05-01-preview" -H "Ocp-Apim-Subscription-Key:YOUR_SUBSCRIPTION_KEY_HERE" -H "Content-Type: application/json" -H "x-ms-useragent: cu-sample-code" --data @Tax-Doc-Analyer-Simple-Schema.json
   ~~~
   ```

## Use Curl to test the parasing of a file in an Azure Storage Account
The following Curl command can be used in a Windows Terminal window.

   ```
        curl -i -X POST "https://YOUR_RESOURCE_HERE.cognitiveservices.azure.com/contentunderstanding/analyzers/YOUR_ANALYZER_KEY_HERE:analyze?api-version=2025-05-01-preview&stringEncoding=utf16" `
        -H "Ocp-Apim-Subscription-Key: your key goes here" `
        -H "Content-Type: application/json" `
        -H "x-ms-useragent: cu-sample-code" `
        -d '{"url":"https://YOUR_URL_TO_FILE_IN_BLOB_STROAGE"}'
   ```

   If the POST was submitting successfully, you will get a response that looks like the following:

   [Custom-Analyzer-Response](../../images/custom-analyzer-response.jpg)

## Use Curl to poll for the status of the job
Once you receive the response from the POST request to analyze the Tax Document, you will need to store the value of the `Operation-Location` so you can poll for the status of the job.  Below is an example of a **Curl** command you can use for this.

   ```
     curl -i -X GET "YOUR_OPERATION_LOCATION_URL_HERE" -H "Ocp-Apim-Subscription-Key:YOUR_SUBSCRIPTION_KEY_HERE" -H "Content-Type: application/json" -H "x-ms-useragent: cu-sample-code"
   ```
## Use Curl to list all Analyzers for Content Understanding
The Curl command below will list all Analyzers inlcude the Analyzers you have created with a custom schema.  If you want to filter out all the prebuilt analyzers you can write a PowerShell script to do so and just parse the JSON response and filter out the prebuilt ones.

   ```
     curl -i -X GET "https://YOUR_RESOURCE_HERE.cognitiveservices.azure.com/contentunderstanding/analyzers?api-version=2025-05-01-preview" -H "Ocp-Apim-Subscription-Key:YOUR_SUBSCRIPTION_KEY" -H "x-ms-useragent: cu-sample-code"
   ```

## Use Curl to create a custom Analzyer or to update the schema
The following Curl Command is an example of how to update an existing schema for a custom Analyzer you have deployed. If you want to extract all the fields, you will need to leverage the `Tax-Doc-Analyzer-Schema.json` found in the **scheams** folder.

   ```
    curl -i -X PUT "https://YOUR_RESOURCE_HERE.cognitiveservices.azure.com/contentunderstanding/analyzers/CDM-Smith-Tax-Analyzer?api-version=2025-05-01-preview" -H "Ocp-Apim-Subscription-Key:YOUR_API_KEY_HERE" -H "Content-Type: application/json" -H "x-ms-useragent: cu-sample-code" -d "{\"description\":\"Simplified Tax Document Analyzer - 2 Fields Only\",\"baseAnalyzerId\":\"prebuilt-documentAnalyzer\",\"config\":{\"returnDetails\":false,\"estimateFieldSourceAndConfidence\":false,\"enableOcr\":true,\"enableLayout\":true,\"enableFormula\":false,\"disableContentFiltering\":false,\"tableFormat\":\"html\"},\"fieldSchema\":{\"fields\":{\"taxpayer_name\":{\"type\":\"string\",\"method\":\"extract\",\"description\":\"Extract the primary taxpayer's full name or business entity name\"},\"tax_jurisdiction\":{\"type\":\"string\",\"method\":\"extract\",\"description\":\"The governmental authority responsible for the tax\"}}}}"
   ```

## Use Curl to delete the custom Analyzer from Content Understanding

   ```
      curl -i -X DELETE "https://YOUR_RESOURCE_HERE.cognitiveservices.azure.com/contentunderstanding/analyzers/YOUR_ANALYZER_ID_HERE?api-version=2025-05-01-preview" -H "Ocp-Apim-Subscription-Key:YOUR_SUBSCRIPTION_KEY" -H "x-ms-useragent: cu-sample-code"
   ```

   You can navigate to the **schemas** folder in the Terminal window and use the following Curl command to just point to the local schema file.

   ```
        curl -i -X PUT "https://rdc-cdm-smith-tax-doc-resource.cognitiveservices.azure.com/contentunderstanding/analyzers/Simple-Tax-Analyzer?api-version=2025-05-01-preview" -H "Ocp-Apim-Subscription-Key:6dUm2iA5ciDQIsbj3TJxhC60Z3J9TEDp87nRoMeDLDoxWMm2qQj1JQQJ99BHAC4f1cMXJ3w3AAAAACOGzWBp" -H "Content-Type: application/json" -H "x-ms-useragent: cu-sample-code" --data @Tax-Doc-Analyer-Simple-Schema.json
   ~~~

   This command can take a few minutes to finish creating the Analyzer, but you can check the status using the following Curl command:

   ```
      # Get details for your specific analyzer
        curl -i -X GET "https://rdc-cdm-smith-tax-doc-resource.cognitiveservices.azure.com/contentunderstanding/analyzers/Simple-Tax-Analyzer?api-version=2025-05-01-preview" -H "Ocp-Apim-Subscription-Key:6dUm2iA5ciDQIsbj3TJxhC60Z3J9TEDp87nRoMeDLDoxWMm2qQj1JQQJ99BHAC4f1cMXJ3w3AAAAACOGzWBp" -H "x-ms-useragent: cu-sample-code"
   ```

***Remove this before committing to GitHub Repp***

   ```
        curl -i -X POST "https://rdc-cdm-smith-tax-doc-resource.cognitiveservices.azure.com/contentunderstanding/analyzers/CDM-Smith-Tax-Analyzer:analyze?api-version=2025-05-01-preview&stringEncoding=utf16&enableJailbreakDetection=false" `
        -H "Ocp-Apim-Subscription-Key:6dUm2iA5ciDQIsbj3TJxhC60Z3J9TEDp87nRoMeDLDoxWMm2qQj1JQQJ99BHAC4f1cMXJ3w3AAAAACOGzWBp" `
        -H "Content-Type: application/json" `
        -H "x-ms-useragent: cu-sample-code" `
        -d '{"url":"https://stgcdmtaxdocswest.blob.core.windows.net/incoming/tax_notice_business_license_1754332187471.pdf"}'

   ```

   ```
        curl -i -X GET "https://rdc-cdm-smith-tax-doc-resource.cognitiveservices.azure.com/contentunderstanding/analyzerResults/bd4ec518-8171-4a95-9300-8421af7f0e54?api-version=2025-05-01-preview" -H "Ocp-Apim-Subscription-Key:6dUm2iA5ciDQIsbj3TJxhC60Z3J9TEDp87nRoMeDLDoxWMm2qQj1JQQJ99BHAC4f1cMXJ3w3AAAAACOGzWBp" -H "Content-Type: application/json" -H "x-ms-useragent: cu-sample-code"
   ```

   ```
       # Delete your existing analyzer - Windows Command Prompt
        curl -i -X DELETE "https://rdc-cdm-smith-tax-doc-resource.cognitiveservices.azure.com/contentunderstanding/analyzers/CDM-Smith-Tax-Analyzer?api-version=2025-05-01-preview" -H "Ocp-Apim-Subscription-Key:6dUm2iA5ciDQIsbj3TJxhC60Z3J9TEDp87nRoMeDLDoxWMm2qQj1JQQJ99BHAC4f1cMXJ3w3AAAAACOGzWBp" -H "x-ms-useragent: cu-sample-code"
   ```

   ```
      # List all your custom analyzers - Windows Command Prompt
        curl -i -X GET "https://rdc-cdm-smith-tax-doc-resource.cognitiveservices.azure.com/contentunderstanding/analyzers?api-version=2025-05-01-preview" -H "Ocp-Apim-Subscription-Key:6dUm2iA5ciDQIsbj3TJxhC60Z3J9TEDp87nRoMeDLDoxWMm2qQj1JQQJ99BHAC4f1cMXJ3w3AAAAACOGzWBp" -H "x-ms-useragent: cu-sample-code"
   ```

   ```
```
    # Curl command to update a schema
    curl -i -X PUT "https://rdc-cdm-smith-tax-doc-resource.cognitiveservices.azure.com/contentunderstanding/analyzers/CDM-Smith-Tax-Analyzer?api-version=2025-05-01-preview" -H "Ocp-Apim-Subscription-Key:6dUm2iA5ciDQIsbj3TJxhC60Z3J9TEDp87nRoMeDLDoxWMm2qQj1JQQJ99BHAC4f1cMXJ3w3AAAAACOGzWBp" -H "Content-Type: application/json" -H "x-ms-useragent: cu-sample-code" -d "{\"description\":\"Simplified Tax Document Analyzer - 2 Fields Only\",\"baseAnalyzerId\":\"prebuilt-documentAnalyzer\",\"config\":{\"returnDetails\":false,\"estimateFieldSourceAndConfidence\":false,\"enableOcr\":true,\"enableLayout\":true,\"enableFormula\":false,\"disableContentFiltering\":false,\"tableFormat\":\"html\"},\"fieldSchema\":{\"fields\":{\"taxpayer_name\":{\"type\":\"string\",\"method\":\"extract\",\"description\":\"Extract the primary taxpayer's full name or business entity name\"},\"tax_jurisdiction\":{\"type\":\"string\",\"method\":\"extract\",\"description\":\"The governmental authority responsible for the tax\"}}}}"
   ```
   ```
