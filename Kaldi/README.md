This directory contains scripts for the following:

1. Kaldi Data Preparation
  Scripts for generating the data preparation files required by Kaldi for training and running ASR models. 
  See [here](https://chrisearch.wordpress.com/2017/03/11/speech-recognition-using-kaldi-extending-and-using-the-aspire-model/)for more details about what Kaldi expects for data preparation.
  The relevant files are prep_asr_data_dir.sh and prep_asr_data.py (which is used by prep_asr_data_dir.sh as a helper script).
  To prepare your dataset using these scripts, follow these steps:
  * Install Kaldi. Instructions for this can be found [here]()
  * Make sure all the audio files you want to transcribe are in a single directory
  * Make sure your audio files are named in the form <audio_file_id>.<file_extention>
  * Create a text file that contains a mapping between the audio file ids and the speaker ids associated with them. This file should contain lines of the form <audio_file_id> <speaker_id> (where the two are separated by a single space).
  * Run the following command: 
        prep_asr_data_dir.sh --audio_dir <path to directory with your audio files> \
                             --output_dir <path data prep directory to create> \
                             --metadata_file_path <path to text file mapping audio ids to speaker ids>\
                             --kaldi_dir <

                                  
