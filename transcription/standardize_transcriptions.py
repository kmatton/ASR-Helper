import os
import re
import argparse

import pandas as pd

from text_processor_factory import get_text_processor


""" 
Script to standardize the notation (e.g. punctuation, spelling, etc.) of audio transcriptions.
This can be used to make notation consistent across reference and ASR transcripts to support better evaluation of WER.
It also can be used to prepare transcriptions for use in model training (e.g. with Microsoft Custom Speech model training).
"""


def write_transcript(data_df, id_col_name, text_col_name, tp, out_file):
    for _, row in data_df.iterrows():
        segment = row[text_col_name]
        seg_id = row[id_col_name]
        if not isinstance(segment, str):
            print("WARNING: seg id {} transcript has empty text".format(seg_id))
            continue
        text = tp.process_transcribed_text(segment)
        out_file.write("{} {}\n".format(seg_id, text))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--transcription_file', type=str, help='Path to csv file containing audio file transcriptions. Should'
                                                               ' contain a column with audio file ids and a column with the'
                                                               ' associated transcriptions.')
    parser.add_argument('--id_col_name', type=str, help='Name of column in transcription file that contains segment IDs.')
    parser.add_argument('--transcript_col_name', type=str, help='Name of column in transcription file that contains transcriptions.')
    parser.add_argument('--output_file', type=str, help='Path to text file to write output transcriptions to.')
    parser.add_argument('--text_processor', type=str, default='Microsoft', help='Name of text processor to use when normalizing transcriptions.' 
                                                              ' Should be chosen based on desired downstream application. Currently, the only option'
                                                              ' is "Microsoft", which processes transcripts to be in the form expected by Azure Speech Services.'
                                                              ' More options (such as for use with Kaldi models) will be added eventually.')
    args = parser.parse_args()
    text_processor = get_text_processor(args.text_processor)
    data_df = pd.read_csv(args.transcription_file)
    out_file = open(args.output_file, 'w+')
    write_transcript(data_df, args.id_col_name, args.transcript_col_name, text_processor, out_file)
    out_file.close()
    

if __name__ == "__main__":
    main()
