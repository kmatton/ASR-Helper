import argparse
import os

import pandas as pd


"""
Script for converting the Microsoft speech recognition results produced by speech_to_text.py
into the format expected for them to be used as input for Word Error Rate (WER) computation. See
the evaluation directory for more on how to compute WERs.
"""


def create_transcript_file(input_file, output_dir):
    """
    :param input_file: recognition_results.csv file containing output from Microsoft speech-to-text model.
                       Must contain 'text_basic' column (this is the output needed for WER computation).
    :param output_dir: path to directory to output transcript file to.
    """
    df = pd.read_csv(input_file)
    df.set_index('audio_file_id', inplace=True)
    output_file = open(os.path.join(output_dir, "microsoft_transcript_basic_text.txt"), 'w+')
    for idx in df.index.values:
        # note: basic text doesn't include most capitalization and punctuation,
        # but it does include apostrophes and capitalization for acronyms
        text = " ".join(df.loc[idx].sort(by='segment_order')['text_basic'])
        # convert to lowercase so that WER doesn't account for casing differences
        text = text.lower()
        output_file.write(f"{idx} {text}\n")
    output_file.close()


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--input_file', type=str, help="Path to recognition_results.csv file as produced by speech_to_text.py")
    parser.add_argument('--output_dir', type=str, help="Path to directory to save output transcript file to.")
    return parser.parse_args()


def main():
    args = parse_args()
    create_transcript_file(args.input_file, args.output_dir)


if __name__ == "__main__":
    main()
