# Tax-Document-Analyzer-Schema.JSON
This scheam is used to define the fields for the Content Understanding Analyzer.

## Config Settings
It's important to note that I have the **returnDetails** and **estimateFieldSourceAndConfidence** score set to **false**.  The reason for this, is I want the API to only return the fields that were extracted from the document.  If you want to get more details like confidence scores for each field and other metadata, you can just parse those details out from the response.  You can simply change these values to **true** before you create the analyzer.

"returnDetails": false,
		"estimateFieldSourceAndConfidence": false,