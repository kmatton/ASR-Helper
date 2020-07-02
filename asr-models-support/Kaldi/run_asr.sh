#!/bin/bash

# Script to run pre-trained ASR model on audio data after data dir is prepared according to Kaldi requirements

# uses parse_options.sh script (given in Kaldi) to enable the specification of command line arguments
# speificy arguments like: --argument value
# arguments for this script are:
# --data_dir: Path to data dir associated with data you want to run ASR on (as prepared by prep_asr_data_dir.sh script)
# --kaldi_dir: Path to Kaldi directory that contains data dir (e.g. kaldi-5.2/egs/<some dataset>/s5)
# --stage: Integer to indicate starting point within the script. Useful if want to restart partway after
#          only partially successful execution. (Optional arg, must be 0 or 1 if provided)
# --groups_file: path of file that has names of groups if data was split into groups during data prepartion step.
# --output_dir: directory for storing lattice files and decoded text files (must already exist)
# --decode_config: path of configuration file to use during decoding (path starting from kaldi_dir, not full path)
# --word_symbol_table: file to use when mapping between symbols (how Kaldi stores words internally) and words (path starting from kaldi_dir, not full path)
# --mdl_path: path to file containing acoustic model (path starting from kaldi_dir, not full path)
# --hclg_path: path to the HCLG WFST graph (path starting from kaldi_dir, not full path)

# set default argument values

# setup / directory arguments
data_dir=
kaldi_dir=
stage=0
groups_file=
output_dir=

# decoding arguments
decode_config='exp/tdnn_7b_chain_online/conf/online.conf'
word_symbol_table='exp/tdnn_7b_chain_online/graph_pp/words.txt'
mdl_path='exp/tdnn_7b_chain_online/final.mdl'
hclg_path='exp/tdnn_7b_chain_online/graph_pp/HCLG.fst'

source ~/.bashrc

. parse_options.sh

# cd into kaldi
cd $kaldi_dir

. ./cmd.sh
. ./path.sh

# STAGE 0: create lattice files
if [ $stage -le 0 ]; then
  options_str="--online=false --do-endpointing=false --frame-subsampling-factor=3 --config=$decode_config --max-active=7000 \
    --beam=15.0 --lattice-beam=6.0 --acoustic-scale=1.0 --word-symbol-table=$word_symbol_table"
   # if groups file specified, run lattice creation for each group in parallel
   # also, filepath names in lattice_cmd differ because they include group names
  if [ ! -z "$groups_file" ]; then
    lattice_cmd="online2-wav-nnet3-latgen-faster $options_str $mdl_path $hclg_path ark:$data_dir/{}/spk2utt \
      scp:$data_dir/{}/wav.scp ark:$output_dir/lattice_{}"
    xargs -a $groups_file -i -P 16 sh -c "$lattice_cmd"
  else
    online2-wav-nnet3-latgen-faster $options_str --num-threads-startup 16 $mdl_path $hclg_path ark:$data_dir/spk2utt \
      scp:$data_dir/wav.scp ark:$output_dir/lattice
  fi
fi

exit

# STAGE 1: decode lattice files to get text files
if [ $stage -le 1 ]; then
  # if groups file specified, run decoding for each group in parallel
  if [ ! -z "$groups_file" ]; then
    decode_cmd="lattice-best-path 'ark:$output_dir/lattice_{}' \
      'ark,t:|int2sym.pl -f 2- $word_symbol_table > $output_dir/decoded_text_{}.txt'"
    xargs -a $groups_file -i -P 16 sh -c "$decode_cmd"
  else
    lattice-best-path 'ark:$ouptut_dir/lattice' \
      'ark,t:|int2sym.pl -f 2- $word_symbol_table > $output_dir/decoded_text.txt'
  fi
fi
