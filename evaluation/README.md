This directory contains scripts for evaluating the performance of an ASR model.

## Prerequisites
* Kaldi


## Computing Word Error Rate (WER)

To compute the WER of transcripts produced by an ASR model, complete the following steps:
1. (prepare reference + transcript files & normalization notation). 
2. Run the following command
```score_transcriptions.sh <path to Kaldi s5 directory> <path to reference transcript> <path to ASR transcript> <path to output file>```