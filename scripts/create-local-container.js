const { BlobServiceClient } = require('@azure/storage-blob');

async function createContainer() {
  try {
    // Connection string for local Azurite
    const connectionString = "UseDevelopmentStorage=true";
    
    // Create the BlobServiceClient
    const blobServiceClient = BlobServiceClient.fromConnectionString(connectionString);
    
    // Container name
    const containerName = "tax-documents";
    
    // Get container client
    const containerClient = blobServiceClient.getContainerClient(containerName);
    
    // Create the container
    console.log(`Creating container: ${containerName}`);
    const createContainerResponse = await containerClient.create();
    console.log(`Container created successfully: ${containerName}`);
    console.log(`Container URL: ${containerClient.url}`);
    
    return createContainerResponse;
  } catch (error) {
    console.error(`Error creating container: ${error.message}`);
    // If container already exists, this is fine
    if (error.code === 'ContainerAlreadyExists') {
      console.log('Container already exists, this is okay.');
    } else {
      throw error;
    }
  }
}

// Call the function
createContainer().catch(error => {
  console.error("Error in main function:", error);
});
