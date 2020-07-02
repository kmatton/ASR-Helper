This directory contains scripts to support using Microsoft Azure Speech Services for training and testing ASR models.


Note: if the data you are working with sensitive (e.g. PII), all steps that involve copying
keys or signatures associated with your Azure account or data should be done while
working on a U of M Machine (or other machine with security guarantees). This can be done
by using RDP to connect to a U of M machine. Instructions for connecting to U of M CAEN machines
remotely can be found [here](https://caen.engin.umich.edu/connect/).


### Fine-tuning Microsoft's Speech-to-text Model with the Custom Speech Service
1. Prepare speech + text data.
2. Upload data to Microsoft Azure blob storage.
   * See [here](https://docs.microsoft.com/en-us/azure/storage/common/storage-account-create?tabs=azure-portal) for how to
     create an Azure storage account. Use default settings, except if you have data backed up somewhere else you can set 
     the data redundancy setting to LRS (which is the minimal redundancy strategy + the cheapest strategy).
   * Set a new environment variable to the Azure storage connection string associated with your storage account.
     Instructions for this can be found [here](https://docs.microsoft.com/en-us/azure/storage/blobs/storage-quickstart-blobs-python).
   * Create a new container within your storage account, create blobs for each dataset you want to upload (e.g. fine-tune data and 
     test data), and upload datasets to blob storage. This can be done with the following command:
         python azure_blob_data_upload.py --container_name_prefix <prefix to use when naming container> \
                                          --data_file_paths <list of paths to dataset files to upload> \
                                          --blob_name_prefixes <list of names to give blobs associated with each dataset>
3. Created a user delegation Shared Access Signature (SAS) to delegate access to the Azure blobs you created in Step 2. This is
   needed in order for you to be able to access the data stored in those blobs when using the Custom Speech portal in Step 4.
   Detailed instructions for created an SAS token can be found [here](https://docs.microsoft.com/en-us/rest/api/storageservices/create-user-delegation-sas).
