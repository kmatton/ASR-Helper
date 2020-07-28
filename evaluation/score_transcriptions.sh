#!/bin/bash
transcript_dir=$1
kaldi_dir=$2
cd $2
. ./path.sh
compute-wer --text --mode=present ark:$1/ref_transcript.txt ark:$1/asr_transcript.txt > $working_dir/WER_output.txt