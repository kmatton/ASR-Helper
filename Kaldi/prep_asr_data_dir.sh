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
# --id_mapping_file_path: Path to pickled dictionary containing mapping between ids used to named audio files and ids
#                         that you want to use in your experiments. For example, may want to consistently name segments
#                         <call_id>_<seg_start>_<seg_end> instead of using integer ids given.  (optional arg, default None)
#  --group_size: If not -1, will split data into groups and create multiple directories within the overall data directory
#                so ASR model can be run and different portions of the data separately (may be necessary for really
#                large datasets). Group size is number of audio files to process at once/
#                create a single subdirectory for. (optional arg, default -1)
# --kaldi_dir: Path to Kaldi directory (e.g. kaldi-5.2/egs/<some dataset>/s5) that is base directory to run utils
#              and other scripts

# initialize options with default values
audio_dir=
output_dir=
segments_dir="None"
metadata_file_path=
id_mapping_file_path="None"
group_size=-1
kaldi_dir=

# use parse_options.sh script (given in Kaldi) to enable the specification of command line arguments
# like: --argument value

. parse_options.sh

# run python data prep file to create directories and wav.scp, utt2spk, and segments files
python prep_asr_data_dir.py --audio_dir $audio_dir --output_dir $output_dir --segments_dir $segments_dir \
  --metadata_file_path $metadata_file_path --id_mapping_file_path $id_mapping_file_path --group_size $group_size

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
