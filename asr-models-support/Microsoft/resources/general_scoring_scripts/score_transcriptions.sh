#!/bin/bash
working_dir=$1
cd /nfs/turbo/McInnisLab/Katie/kaldi-5.2/egs/aspire/s5
. ./path.sh
compute-wer --text --mode=present ark:$working_dir/ref_transcript.txt ark:$working_dir/asr_transcript.txt > $working_dir/WER_output.txt
