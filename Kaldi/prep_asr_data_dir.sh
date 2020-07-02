#!/bin/bash

# Script to run Kaldi data preparation
# Creates data directory with necessary metadata files

source ~/.bashrc

# arguments for this script are:
# --audio_dir: Directory containing audio wav files. It is assumed that files are named call_id.wav or segment_id.wav
# --output_dir: Directory to output ASR prep files to.
# --segments_dir: Directory containing files with segment times for each call audio file. Expect each file in the
#                 directory to be named call_id.txt and to contain lines of the form <segment_start> <segment_end>
#                 (in ms). If no segments directory is specified, assume that calls have already been segmented and
#                 audio directory contains segment wav files. (optional arg, default None)
# --metadata_file_path: Path to pickled DataFrame containing metadata information, including mapping between
#                       subject_ids, call_ids, and segment_ids
#  --num_groups: If not 1, will split data into <num_groups> groups and create a directory for each of them within the
#                main data directory. This way the ASR model can be run and different portions of the data separately,
#                which may be necessary for really large datasets. (optional arg, default 1)
# --kaldi_dir: Path to Kaldi directory (e.g. kaldi-5.2/egs/<some dataset>/s5) that is base directory from wich to run
#              data prep utils.
# --convert_file_cmd: Command for converting audio files to WAV PCM format, which is expected by Kaldi. 
#                     Optional, as files may already be in the correct format. Example command is: sox {}  -t wav -r 8000 - |
#                     (should include {} where audio file path should go).

# initialize options with default values
audio_dir=
output_dir=
segments_dir="None"
metadata_file_path=
num_groups=1
kaldi_dir=
convert_file_cmd="None"

# use parse_options.sh script (given in Kaldi) to enable the specification of command line arguments
# ex: --argument value

. parse_options.sh

# run python data prep file to create directories and wav.scp, utt2spk, and segments files
python prep_asr_data_dir.py --audio_dir $audio_dir --output_dir $output_dir --segments_dir $segments_dir \
  --metadata_file_path $metadata_file_path --num_groups $num_groups --convert_file_cmd $convert_file_cmd

# sort files
cd $output_dir
declare -a arr=('wav.scp' 'utt2spk' 'text')
for fname in ${arr[@]}; do
  for f in $(find . -name $fname); do
    sort $f > ${f}_sorted
    rm $f
    mv ${f}_sorted $f
  done
done

# make spk2utt files
cd $kaldi_dir
. ./cmd.sh
. ./path.sh
for f in $(find $output_dir -name utt2spk); do
  ./utils/utt2spk_to_spk2utt.pl $f > $(dirname $f)/spk2utt
done
