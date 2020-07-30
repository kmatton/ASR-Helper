#!/bin/bash
kaldi_dir=$1
ref_file_path=$2
asr_file_path=$3
output_file_path=$4

cd $kaldi_dir || exit

. ./path.sh
compute-wer --text --mode=present ark:$ref_file_path ark:$asr_file_path > $output_file_path
