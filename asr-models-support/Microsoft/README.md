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
2. Use the Microsoft Azure portal to create a speech resource. Instructions for doing this can be found [here](https://docs.microsoft.com/en-us/azure/cognitive-services/speech-service/get-started#create-the-resource). Make sure to choose the 'Standard S0' pricing tier.
3. Log into the Custom Speech Portal and create a new project. Instructions for doing this can be found [here](https://docs.microsoft.com/en-us/azure/cognitive-services/speech-service/how-to-custom-speech#how-to-create-a-project).
4. Upload your data to the Custom Speech portal, following [these instructions](https://docs.microsoft.com/en-us/azure/cognitive-services/speech-service/how-to-custom-speech-test-and-train#upload-data).
5. Train a model by following [these instructions](https://docs.microsoft.com/en-us/azure/cognitive-services/speech-service/how-to-custom-speech-train-model).
6. Evaluate the accuracy of your model by following [these instructions](https://docs.microsoft.com/en-us/azure/cognitive-services/speech-service/how-to-custom-speech-inspect-data).
7. Deploy your model via [these instructions](https://docs.microsoft.com/en-us/azure/cognitive-services/speech-service/how-to-custom-speech-deploy-model).

Note: I found that for the dataset I was working with ([the PRIORI emotion dataset](https://arxiv.org/abs/1806.10658)), Microsoft's baseline model actually performed better than a model fine-tuned on the data via the steps described above. Therefore, this section may or may not end up being useful to you! You should consider your specific dataset and performance needs when deciding whether using a custom speech model is worth it.


### Using a Microsoft Speech-to-text Model to Transcribe your Data
These instructions and the scripts mentioned in this section were created based on the Microsoft speech-to-text documentation found [here](https://docs.microsoft.com/en-us/azure/cognitive-services/speech-service/speech-to-text-basics?tabs=import&pivots=programming-language-python), as well as the articles mentioned in the [extentions section](#extentions) below.

To use a speech-to-text model to transcribe your data, follow these steps:
1. Install the Python Microsoft Speech SDK with the following command: 
    pip install azure-cognitiveservices-speech
If you are using a machine with Red Hat Enterprise Linux / Centos07, setting up the Speech SDK may take a few extra steps. They are described [here](https://docs.microsoft.com/en-us/azure/cognitive-services/speech-service/how-to-configure-rhel-centos-7). I personally found that in order to get the Python Speech SDK working on a machine with Centos07 ([Armis2](https://arc-ts.umich.edu/armis2/)), I didn't actually need to follow all of the steps described. I just needed to execute the command `export SSL_CERT_FILE=/etc/pki/tls/certs/ca-bundle.crt` before using the Python SDK.
2. If you haven't already created a Speech Resource through the Microsoft Azure portal, follow [these instructions](https://docs.microsoft.com/en-us/azure/cognitive-services/speech-service/get-started#create-the-resource) to do so.
3. Copy the subscription key associated with a Speech Resource. To do this, navigate to the Speech Resource you want to use within the Microsoft Azure portal. On the left sidebar, click "Keys and Endpoint." Then copy either "Key1" or "Key2" (it doesn't matter which one).
4. Write the subscription key to an environment variable called `SPEECH_SUBSCRIPTION_KEY` on the machine you are working on. This can be done with the command `export SPEECH_SUBSCRIPTION_KEY="<your subscription key>"`. Because the key enables access to your Cognitive Services API, it is important to make sure it is stored securely. Therefore, you should not to write this key to a file and instead store it as a temporary environment variable via the command previously described.
5. Create a text file specifing the ids and filepaths of the audio files you want to transcribe. Each line of the file should be of the form `<audio file id> <path to audio file>` where a single space separates the two items.
6. To transcribe the files, run this command:
    python speech_to_text.py --audio_files <path to your text file from step #5> --output_dir <directory to output transcriptions to>
See the script for more details on the arguments and other optional arguments you can use.


#### Extensions
If you wish to adapt the scripts described above for your own purposes, the following documentation may be useful:
* This [article](https://docs.microsoft.com/en-us/azure/cognitive-services/speech-service/rest-speech-to-text#query-parameters) describes the Speech Recognition response parameters for the REST API, which I found to be the same as the response parameters for the Speech SDK (I could not found a similar article describing the parameters for the speech SDK).
* To change which response parameters (as decribed in the above article) the Speech Recongizer outputs, you need to adapt the SpeechConfig. This [documentation](https://docs.microsoft.com/en-us/python/api/azure-cognitiveservices-speech/azure.cognitiveservices.speech.speechconfig?view=azure-python) of the SpeechConfig class is useful in figuring out how to do that.
* This [documentation](https://docs.microsoft.com/en-us/dotnet/api/microsoft.cognitiveservices.speech.profanityoption?view=azure-dotnet
) lists the different options for the ProfanityOption enum (provided as an argument when setting the profanity level of the Speech Config).
* This [article](https://docs.microsoft.com/en-us/azure/cognitive-services/speech-service/rest-speech-to-text#pronunciation-assessment-parameters) describes speech recognition response options related to evaluating the pronunciation accuracy of an audio file. Note that the pronunciation calculation requires a reference text document (e.g. a human-labeled transcript). Because we don't have this for most of the PRIORI data, I did not use this feature as part of the speech-to-text generation scripts described above.

### Subdirectories
The subdirectories within this directory are as follows:
* sample_data: contains audio and transcript data that Microsoft provides as examples of how data should be formated when working with the Custom Speech service. Data was downloaded from [here](https://github.com/Azure-Samples/cognitive-services-speech-sdk/tree/master/sampledata/customspeech/en-US).
* resources: contains miscellaneous, undocumented scripts that contain additional functionality to support working with Microsoft Azure. Documentation for these scripts will be added eventually.

### Other Microsoft Speech Services documentation that may be useful
*  Intent recognition: https://docs.microsoft.com/en-us/azure/cognitive-services/speech-service/index-intent-recognition