#!/bin/bash

# Script to collect aligned word and phone timing annotations for transcripts.

# arguments for this script are:
# --lattice_dir: directory where lattice file(s) are stored
# --zipped_lattices: [0 | 1] to indicate if lattices are stored as zipped .gz files (1 = True)
#                    (if so, need to unzip them)
# --kaldi_dir: Path to Kaldi directory that contains data dir (e.g. kaldi-5.2/egs/<some dataset>/s5)
# --stage: Integer to indicate starting point within the script. Useful if want to restart part way after
#          only partially successful execution.
# --groups_file: path of file that has names of groups if data was split into groups during data prepartion step.
# --output_dir: directory for storing aligned timing annotations and other files created in generating them
# --mdl_path: path to file containing acoustic model
# --word_bndry_path: path to word boundary file (contains mapping from phone ids to placement within words)
# --word_symbol_table: file to use when mapping between symbols (how Kaldi stores words internally) and words
# --phone_symbol_table: file to use when mapping between symbols (how Kaldi stores words internally) and phones
# --lexicon_path: phone mapping words to their phonetic readings

# set default argument values

# setup / directory arguments
lattice_dir=
zipped_lattices=0
kaldi_dir=
stage=0
groups_file=
output_dir=

# arguments for files associated with ASR model
mdl_path='exp/tdnn_7b_chain_online/final.mdl'
word_bndry_path='exp/tdnn_7b_chain_online/graph_pp/phones/word_boundary.int'
word_symbol_table='exp/tdnn_7b_chain_online/graph_pp/words.txt'
phone_symbol_table='exp/tdnn_7b_chain_online/phones.txt'
lexicon_path='data/local/dict/lexicon4_extra.txt'

source ~/.bashrc

# use parse_options.sh script (given in Kaldi) to enable the specification of command line arguments
# like: --argument value
. parse_options.sh

# save directory this script is run from
base_dir=$PWD


# cd into kaldi
cd $kaldi_dir

. ./cmd.sh
. ./path.sh

# save lattice file name as variable
lattice=
if [ ! -z "$groups_file" ]; then
  lattice="$lattice_dir/lattice_{}"
else
  lattice="$lattice_dir/lattice"
fi

if [ $zipped_lattices -eq 1 ]; then
  lattice="ark:gunzip -c $lattice |"
else
  lattice="ark:$lattice"
fi

# STAGE 0: Get aligned timing of phones
if [ $stage -le 0 ]; then
  # if groups file is specified, run timing annotation collection on each group in parallel
  if [ ! -z "$groups_file" ]; then
    phone_ali_cmd="lattice-1best --acoustic-scale=0.1 \"$lattice\" ark:- | nbest-to-linear ark:- ark:- | \
      ali-to-phones --write-lengths $mdl_path ark:- ark,t:$output_dir/ali_phones_with_length_{}.txt"
    xargs -a $groups_file -i -P 16 sh -c "$phone_ali_cmd"
  else
    lattice-1best --acoustic-scale=0.1 "$lattice" ark:- | nbest-to-linear ark:- ark:- | \
    ali-to-phones --write-lengths $mdl_path ark:- ark,t:$output_dir/ali_phones_with_length.txt
  fi
fi

# STAGE 1: Get transcript that contains words given by decoding step that involved calculating aligned word timing info
# note: you may be able to use transcripts obtained differently (e.g. directly from lattice-best-path command)
# but I'm not sure and have included these steps to be safe
if [ $stage -le 1 ]; then
  # if groups file is specified, run timing annotation collection on each group in parallel
  if [ ! -z "$groups_file" ]; then
    # create file with word-level aligned timing annotations
    word_ali_cmd="lattice-1best --acoustic-scale=0.1 \"$lattice\" ark:- | \
    lattice-align-words $word_bndry_path $mdl_path ark:- ark:- | nbest-to-ctm ark:- - | \
    utils/int2sym.pl -f 5 $word_symbol_table > $output_dir/lattice_decoding_{}.ctm"
    xargs -a $groups_file -i -P 16 sh -c "$word_ali_cmd"

    # create transcript (each line as <utt_id> <text>) based on word-level aligned timing file
    trnscrb_cmd="python $base_dir/create_transcript_from_ctm.py $output_dir/lattice_decoding_{}.ctm $output_dir/ali_word_text_{}.txt"
    xargs -a $groups_file -i -P 16 sh -c "$trnscrb_cmd"
  else
    # create file with word-level aligned timing annotations
    lattice-1best --acoustic-scale=0.1 "$lattice" ark:- | \
    lattice-align-words $word_bndry_path $mdl_path ark:- ark:- | nbest-to-ctm ark:- - | \
    utils/int2sym.pl -f 5 $word_symbol_table > $output_dir/lattice_decoding.ctm

    # create transcript (each line as <utt_id> <text>) based on word-level aligned timing file
    python $base_dir/create_transcript_from_ctm.py $output_dir/lattice_decoding.ctm $output_dir/ali_word_text.txt
  fi
fi

# STAGE 2: Use aligned phone timing file and transcript file to get aligned word + phone timing.
if [ $stage -le 2 ]; then
  # if groups file is specified, run timing annotation collection on each group in parallel
  if [ ! -z "$groups_file" ]; then
    ali="$output_dir/ali_phones_with_length_{}.txt"
    word_text="$output_dir/ali_word_text_{}.txt"
    phone2word_ali_cmd="python $CHAI_SHARE_PATH/Bins/kaldi/phone2word_ali.py $ali $word_text $phone_symbol_table \
      $lexicon_path --sil-phones 1 2 3 4 5 > $output_dir/word_phone_ali_timing_{}.txt"
    echo "phone 2 word ali command: $phone2word_ali_cmd"
    xargs -a $groups_file -i -P 16 sh -c "$phone2word_ali_cmd"
  else
    ali="$output_dir/ali_phones_with_length.txt"
    word_text="$output_dir/ali_word_text.txt"
    python $CHAI_SHARE_PATH/Bins/kaldi/phone2word_ali.py $ali $word_text $phone_symbol_table \
      $lexicon_path --sil-phones 1 2 3 4 5 > $output_dir/word_phone_ali_timing.txt
  fi
fi

