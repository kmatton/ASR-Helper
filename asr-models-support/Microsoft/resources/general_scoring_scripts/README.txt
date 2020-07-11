This directory contains scripts for computing word error rates. 

General notes:

When using these scripts, transcripts are first converted to all lower case and punctuation (aside from apostrophes) is removed. This means that correct casing and punctuation is not considered when computing WER.

Some notes on each file:

-- process_text.py: contains functions for processing text (i.e. changing case, removing punctuation, standardizing spelling, etc.). This is used by standardize_transcriptions.py.

-- standardize_transcriptions.py: script used to standardize the notation of ground truth / reference transcriptions and ASR transcriptions. Takes as input a csv file with rows 
                                  corresponding to speech segments and three columns: segment ID, reference text, and ASR text. See the argument descriptions in that file for details. 
                                  Outputs two files: ref_transcript.txt (reference transcriptions post-standardization) and asr_transcript.txt (ASR transcriptions post-standardization).

-- score_transcriptions.sh: script that runs the Kaldi compute-wer function on the ref_transcript.txt and asr_transcript.txt files. Note that near the top of that script, there is a 
                            line "cd /nfs/turbo/McInnisLab/Katie/kaldi-5.2/egs/aspire/s5." This is included because in order to run the Kaldi compute-wer function, it's easiest to be inside one of                             the "s5" subdirectories in Kaldi. If you are run this on a different machine than armis2, you'll want to change this line to point to an s5 directory within where you 
                            have Kaldi installed.



Step by step instructions on how to run the scripts to compute the WER:

1. Prepare a csv file with a row for each speech segment and three columns per segment: segment_ID (these need to be unique to each segment), reference_text, and asr_text.

2. Run python standardize_transcriptions.py -t <name of csv file from step 1> -i <segment ID column name> -r <reference text column name> -a <ASR text column name> -o <output directory>

3. If you are not working on armis, change the line  "cd /nfs/turbo/McInnisLab/Katie/kaldi-5.2/egs/aspire/s5" in score_transcriptions.sh to instead reference where you have Kaldi 
   installed on your machine.

4. Run ./score_transcriptions.sh <working dir>. This will output the WER results to a file <working_dir>/WER_output.txt. Make sure that <working dir> is also where the ref_transcript.txt 
   and asr_transcript.txt files generated in step #2 are stored and that it as an absolute path (not relative path).
