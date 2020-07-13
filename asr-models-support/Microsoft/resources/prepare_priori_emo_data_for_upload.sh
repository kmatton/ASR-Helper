#!/bin/bash

# for both asessments and personal calls,
# copy segment audio files form each subject into a single directory
priori_emo_dir_in='/nfs/turbo/McInnisLab/Soheil/IS2018_priori_emotion/priori_emotion_db/wav'
priori_emo_dir_out='priori_emo_data'
mkdir $priori_emo_data_out

data_types=( "personal" "assessment" )

for data_type in "${data_types[@]}"
do
    root_dir=$priori_emo_dir_in/exp_$data_type
    for sub_dir in "$root_dir"/*
    do
        # create new directory to store this subject's segments
        sub_name="$(basename $sub_dir)"
        sub_out_dir="${priori_emo_data}/${sub_name}_${data_type}"
        mkdir $sub_out_dir
        for call_dir in "$sub_dir"/*
        do
            call_name="$(basename $call_dir)"
            for segment_file in "$call_dir"/*
            do
            if [[ -f $segment_file ]]
            then
                # copy segment file to subject's new directory
                seg_file_name="$(basename segment_file)"
                cp $segment_file "${sub_out_dir}/${call_name}_${seg_file_name}"
                exit
            fi
            done
        done
        # copy subject specific transcript file into this directory
        cp trans_files_by_sub_exp/${sub_name}_${data_type}.txt $sub_out_dir/trans.txt
        # zip this subject's directory
        zip -r ${sub_out_dir}.zip $sub_out_dir
        rm -r $sub_out_dir
        exit
    done
done