#!/bin/bash
kaldi_dir=$1
ref_file_path=$2
asr_file_path=$3
output_dir=$4
cd $1
. ./path.sh
compute-wer --text --mode=present ark:$2 ark:$3/ > $4/WER_output.txt