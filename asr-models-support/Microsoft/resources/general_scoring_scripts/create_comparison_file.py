import process_text as pt
import os
import pandas as pd
import re
import argparse


""" 
Script that creates file that groups speech segments such that it is easier to visually compare output of two different transcription files.
"""


def write_transcript(data_df, id_col_name, text_col_name, tp, out_file):
    for index, row in data_df.iterrows():
        segment = row[text_col_name]
        seg_id = row[id_col_name]
        if not isinstance(segment, str):
            print("transcribed text is not string: {} for id {}".format(segment, seg_id))
            continue
        text = tp.process_transcribed_text(segment, False, True)
        out_file.write("{} {}\n".format(seg_id, text))

def read_text_file(filepath):
    t_file = open(filepath, 'r')
    ids = []
    texts = []
    for line in t_file.readlines():
        utt_id = line.strip().split(" ")[0]
        text = " ".join(line.strip().split(" ")[1:])
        ids.append(utt_id)
        texts.append(text)
    t_file.close()
    return ids, texts


def read_csv_file(filepath, id_col, text_col):
    df = pd.read_csv(filepath)
    # convert to string so consistent with text file
    ids = [str(utt_id) for utt_id in df[id_col].values]
    texts = list(df[text_col].values)
    return ids, texts


def read_file(filepath, id_col, text_col):
    if filepath.endswith('txt'):
        ids, texts = read_text_file(filepath)
    else:
        ids, texts = read_csv_file(filepath, id_col, text_col)
    return ids, texts

def write_compare_file(name1, ids_1, texts_1, name2, ids_2, texts_2, output_dir):
    o_file = open(os.path.join(output_dir, "compare_{}_{}.txt".format(name1, name2)), 'w+')
    dict_1 = {utt_id: text for utt_id, text in zip(ids_1, texts_1)}
    dict_2 = {utt_id: text for utt_id, text in zip(ids_2, texts_2)}
    o_file.write("Utt ID\n")
    o_file.write("{} transcrition\n".format(name1))
    o_file.write("{} transcription\n".format(name2))
    o_file.write("\n")
    for utt_id in dict_1.keys():
        text1 = dict_1[utt_id]
        if utt_id not in dict_2:
            continue
        text2 = dict_2[utt_id]
        o_file.write(utt_id+"\n")
        o_file.write(text1+"\n")
        o_file.write(text2+"\n")
        o_file.write("\n")
    o_file.close()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--file1', type=str, help='Input file containing speech segment transcriptions from method #1. Expect txt or csv file.')
    parser.add_argument('--id_col_1', type=str, help='If file1 is .csv file, name of column in this file that contains segment IDs.')
    parser.add_argument('--text_col_1', type=str, help='If file1 is .csv, name of column in this file that contains transcription text for method 1.')
    parser.add_argument('-o', '--output_dir', type=str, help='Path to directory to output comparison file to.')
    parser.add_argument('--file2', type=str, help='Input file containing speech segment transcriptions from method #2. Expect txt or csv file.')
    parser.add_argument('--id_col_2', type=str, help='If file2 is .csv file, name of column in this file that contains segment IDs.')
    parser.add_argument('--text_col_2', type=str, help='If file2 is .csv, name of column in this file that contains transcription text for method 2.')
    args = parser.parse_args()
    ids_1, texts_1 = read_file(args.file1, args.id_col_1, args.text_col_1)
    ids_2, texts_2 = read_file(args.file2, args.id_col_2, args.text_col_2)
    name1 = os.path.basename(args.file1)[:-4]
    name2 = os.path.basename(args.file2)[:-4]
    write_compare_file(name1, ids_1, texts_1, name2, ids_2, texts_2, args.output_dir)
     

if __name__ == "__main__":
    main()
