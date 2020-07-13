This directory contains scripts to support using Microsoft Azure Speech Services for training and testing ASR models.


Note: if the data you are working with sensitive (e.g. PII), all steps that involve copying
keys or signatures associated with your Azure account or data should be done while
working on a U of M Machine (or other machine with security guarantees). This can be done
by using RDP to connect to a U of M machine. Instructions for connecting to U of M CAEN machines
remotely can be found [here](https://caen.engin.umich.edu/connect/).


### Prerequisites
In order to use Microsoft Azure Speech Services, you first need to create a Microsoft Azure account. You can create a personal account [here](https://azure.microsoft.com/en-us/free/search/?&ef_id=EAIaIQobChMIjdi3s87F6gIVDdbACh3pcgpEEAAYASAAEgJQ4vD_BwE:G:s&OCID=AID2100131_SEM_EAIaIQobChMIjdi3s87F6gIVDdbACh3pcgpEEAAYASAAEgJQ4vD_BwE:G:s&gclid=EAIaIQobChMIjdi3s87F6gIVDdbACh3pcgpEEAAYASAAEgJQ4vD_BwE). You can also create an account through U of M ITS [here](https://its.umich.edu/computing/virtualization-cloud/microsoft-azure), which will come with elevated security guarantees. Further, when you sign up for a U of M Azure account, you can link your account to an M Community group. If you do this, all members of that group will be co-owners of any Microsoft Azure resource that you create.


### Fine-tuning Microsoft's Speech-to-text Model with the Custom Speech Service
1. Prepare speech + text data according to the instructions found [here](https://docs.microsoft.com/en-us/azure/cognitive-services/speech-service/how-to-custom-speech-test-and-train). The ground truth/ human-labeled transcriptions should be formatted according to the instructions found [here](https://docs.microsoft.com/en-us/azure/cognitive-services/speech-service/how-to-custom-speech-human-labeled-transcriptions). This code repo contains scripts to help convert your transcripts into the format expected by Microsoft. In order to do this, run the following command from within the ASR-Helper/transcription directory:
    python standardize_transcriptions.py --transcription_file <path to CSV file containing your transcriptions> \
                                         --id_col_name <name of column within transcription file that contains audio file ids> \
                                         --transcript_col_name <name of column within transcription file that contains transcription text> \
                                         --output_file_path <path to text file to ouptut normalized transcriptions to> \
                                         --text_processor "Microsoft"
More details on the script options are specified within the script itself.
2. Use the Microsoft Azure portal to create a speech resource. Instructions for doing this can be found [here]().
3. Log into the Custom Speech Portal and create a new project. Instructions for doing this can be found [here]().
4. Upload your data to the Custom Speech portal, following [these instructions]().


### Subdirectories
The subdirectories within this directory are as follows:
* sample_data: contains audio and transcript data that Microsoft provides as examples of how data should be formated when working with the Custom Speech service. Data was downloaded from [here](https://github.com/Azure-Samples/cognitive-services-speech-sdk/tree/master/sampledata/customspeech/en-US).
* resources: contains miscellaneous, undocumented scripts that contain additional functionality to support working with Microsoft Azure. Documentation for these scripts will be added eventually.
