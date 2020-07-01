import argparse, os, pickle
import pandas as pd
import numpy as np
from IPython import embed

"""
Program to prepare data directory in format required to run Kaldi ASR model on call audio.
"""


def isint(value):
  try:
    int(value)
    return True
  except ValueError:
    return False


def write_line_to_wav(wav_scp_file, rec_id, audio_dir, file_name):
    """
    :param wav_scp_file: Opened wav.scp file to write to.
    :param rec_id: Id uniquely identifying audio file (<sub_id>_<call_id> if call files
    or <sub_id>_<call_id>_<seg_start>_<seg_end> if segment files).
    :param audio_dir: Path to directory where audio files are stored.
    :param file_name: Name of audio file to make entry in wav.scp file for.
    """
    file_path = os.path.join(audio_dir, file_name)
    audio_path = "sox {}  -t wav -r 8000 - |".format(file_path)
    out_line = "{} {}\n".format(rec_id, audio_path)
    wav_scp_file.write(out_line)


def write_segment_lines(segments_out_file, file_name, utt2spk_file, rec_id, sub_id, segments_dir):
    """
    :param segments_out_file: Opened segments file to write to.
    :param file_name: Name of audio file to make entry in metadata files for.
    :param utt2spk_file: Opened utt2spk file to write to.
    :param rec_id: Id uniquely identifying audio file (<sub_id>_<call_id> if call files
    or <sub_id>_<call_id>_<seg_start>_<seg_end> if segment files).
    :param sub_id: Speaker/subject ID.
    :param segments_dir: Directory where files with segments times are.
    """
    segments_in = open(os.path.join(segments_dir, "{}.txt".format(file_name[:-4])), 'r')
    for line in segments_in:
        seg_start, seg_end = line.strip().split(" ")
        seg_start, seg_end = float(seg_start), float(seg_end)
        seg_start_str, seg_end_str = str(int(seg_start * 100)), str(int(seg_end * 100))
        # utt_id is <rec_id>_<seg_start_str>_<seg_end_str>
        utt_id = "{}_{}_{}".format(rec_id, seg_start_str, seg_end_str)
        out_line = "{} {}\n".format(utt_id, sub_id)
        utt2spk_file.write(out_line)
        # each line in segments file is utt_id rec_id seg_start seg_end
        out_line = "{} {} {} {}\n".format(utt_id, rec_id, seg_start, seg_end)
        segments_out_file.write(out_line)


def prep_data_dir(output_dir, audio_dir, audio_file_names, meta_df, wav_id_type, id_dict=None, segments_dir=None):
    """
    :param output_dir: Directory to make metadata files in.
    :param audio_dir: Path to directory where audio files are stored.
    :param audio_file_names: Names of audio files to use when making metadata files for in output_dir.
    :param meta_df: DataFrame with metadata for dataset (e.g. such as mappings between speaker ids and call ids).
    :param wav_id_type: call_id or segment_id depending on what types of audio files we have.
    :param id_dict: (optional) Dictionary mapping ids used to name audio files to new id names you want to use.
    :param segments_dir: (optional) Directory where call segment timing information is.
    """
    if not os.path.exists(output_dir):
        os.mkdir(output_dir)
    # create needed metadata files: wav.scp, utt2spk, segments (if relevant)
    wav_scp_file = open(os.path.join(output_dir, "wav.scp"), 'w+')
    utt2spk_file = open(os.path.join(output_dir, "utt2spk"), 'w+')
    if segments_dir and segments_dir != "None":
        segments_out_file = open(os.path.join(output_dir, "segments"), 'w+')
    for file_name in audio_file_names:
        # get call or segment_id (i.e. remove .wav ending)
        data_id = file_name[:-4]
        # convert to int if possible
        if isint(data_id):
            data_id = int(data_id)
        # map to alternate id if id_dict is provided
        if id_dict:
            data_id = id_dict[data_id]
        # get relevant info from metadata dataframe
        sub_id = meta_df[meta_df[wav_id_type] == data_id]["subject_id"].values[0]
        # if sub_id is NaN skip this file
        # NOTE: could change this, but for now won't need data where we don't know subject
        if np.isnan(sub_id):
            continue
        # convert sub_id to int
        sub_id = int(sub_id)
        rec_id = "{}_{}".format(sub_id, data_id)
        write_line_to_wav(wav_scp_file, rec_id, audio_dir, file_name)
        if segments_dir and segments_dir != "None":
            # need to get all segments in call and create a line for each of them in both utt2spk and segments files
            write_segment_lines(segments_out_file, file_name, utt2spk_file, rec_id, sub_id, segments_dir)
            segments_out_file.close()
        else:
            # if no segments dir, data_id is segment_id and we can use rec_id as utt_id in utt2spk file
            out_line = ("{} {}\n".format(rec_id, sub_id))
            utt2spk_file.write(out_line)
    wav_scp_file.close()
    utt2spk_file.close()
    if segments_dir and segments_dir != "None":
        segments_out_file.close()


def prep_data_dirs(args, meta_df, wav_id_type, id_dict=None, group_file=None):
    """
    :param args: Argument Parser argument with member variables corresponding to command line arguments.
    :param meta_df: DataFrame with metadata for dataset (e.g. such as mappings between speaker ids and call ids).
    :param wav_id_type: call_id or segment_id depending on what types of audio files we have.
    :param id_dict: (optional) Dictionary mapping ids used to name audio files to new id names you want to use.
    :param group_file: (optional) Open file to write the names of groups that data is split into to.
    """
    # split data into groups if group_size is given and prepare directory for each group
    audio_file_names = os.listdir(args.audio_dir)
    # filter to only include files that are named *.wav
    audio_file_names = [f for f in audio_file_names if f[-4:] == ".wav"]
    if args.group_size != -1:
        group_num = 0
        for i in range(0, len(audio_file_names), args.group_size):
            group_file_names = audio_file_names[i:i+args.group_size]
            group_out_dir = os.path.join(args.output_dir, "group_{}".format(group_num))
            prep_data_dir(group_out_dir, args.audio_dir, group_file_names, meta_df, wav_id_type,
                          id_dict, args.segments_dir)
            group_file.write("group_{}\n".format(group_num))
            group_num += 1
    else:
        prep_data_dir(args.output_dir, args.audio_dir, audio_file_names, meta_df, wav_id_type,
                      id_dict, args.segments_dir)


def main():
    # Read in and process command line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('-a', '--audio_dir', type=str, help='Directory containing audio wav files. It is assumed that '
                                                            'files are named call_id.wav or segment_id.wav')
    parser.add_argument('-o', '--output_dir', type=str, help='Data directory to output ASR prep files to')
    parser.add_argument('-s', '--segments_dir', type=str, help='Directory containing files with segment times'
                                                               'for each call audio file. Expect each file in the '
                                                               'directory to be named call_id.txt and to contain lines '
                                                               'of the form <segment_start> <segment_end> (in ms). '
                                                               'If no segments directory is specified or "None" is ' 
                                                               'specified, assume that calls have already been '
                                                               'segmented and audio directory contains segment wav '
                                                               'files. ')
    parser.add_argument('-m', '--metadata_file_path', type=str, help='Path to pickled DataFrame containing metadata '
                                                                     'information, including mapping between '
                                                                     'subject_ids, call_ids, and segment_ids')
    parser.add_argument('-i', '--id_mapping_file_path', type=str, help='Path to pickled dictionary containing mapping'
                                                                       'between ids used to named audio files and ids'
                                                                       'that you want to use in your experiments. For'
                                                                       'example, may want to consistently name segments'
                                                                       '<call_id>_<seg_start>_<seg_end> instead of '
                                                                       'using integer ids given.')
    parser.add_argument('-g', '--group_size', type=int, default=-1, help='If not -1, will split data into groups and'
                                                                         'create multiple directories within the'
                                                                         'overall data directory so ASR model can be'
                                                                         'run and different portions of the data'
                                                                         'separately (may be necessary for really large'
                                                                         'datasets). Group size is number of audio'
                                                                         'files to process at once/ create a single' 
                                                                         'subdirectory for.')

    args = parser.parse_args()

    # Determine if audio files are for calls or segments
    wav_id_type = "segment_id"
    if args.segments_dir and args.segments_dir != "None":
        # if directory is specified to hold files with segment times, then wav files are at the call level
        wav_id_type = "call_id"

    # Load metadata file and id mapping dict
    meta_df = pd.read_pickle(args.metadata_file_path)
    id_dict = None
    if args.id_mapping_file_path and args.id_mapping_file_path != "None":
        id_dict_file = open(args.id_mapping_file_path, 'rb')
        id_dict = pickle.load(id_dict_file)
        id_dict_file.close()

    # create file to write group names to if group_size is given
    group_file = None
    if args.group_size != -1:
        group_file = open(os.path.join(args.output_dir, "group_names.txt"), 'w+')

    prep_data_dirs(args, meta_df, wav_id_type, id_dict, group_file)

    group_file.close()


if __name__ == '__main__':
    main()
