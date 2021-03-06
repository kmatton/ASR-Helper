import argparse, os, pickle, math

import numpy as np
from IPython import embed

"""
Script to prepare data directory in format required to run Kaldi ASR model on call audio.
"""


def write_line_to_wav(wav_scp_file, rec_id, audio_dir, file_name, audio_conversion_cmd=None):
    """
    :param wav_scp_file: Opened wav.scp file to write to.
    :param rec_id: Id uniquely identifying audio file (<sub_id>_<call_id> if call files
    or <sub_id>_<call_id>_<seg_start>_<seg_end> if segment files).
    :param audio_dir: Path to directory where audio files are stored.
    :param file_name: Name of audio file to make entry in wav.scp file for.
    :param audio_conversion_cmd: (optional str) command for converting audio files to format expected by Kaldi
    """
    file_path = os.path.join(audio_dir, file_name)
    if audio_conversion_cmd is not None:
        audio_path = audio_conversion_cmd.format(file_path)
    else:
        audio_path = file_path
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


def prep_data_dir(output_dir, audio_dir, audio_file_names, id2sub, segments_dir=None, audio_conversion_cmd=None):
    """
    :param output_dir: Directory to make metadata files in.
    :param audio_dir: Path to directory where audio files are stored.
    :param audio_file_names: Names of audio files to use when making metadata files for in output_dir.
    :param id2sub: Dict mapping ids used in naming audio files to subject ids.
    :param segments_dir: (optional) Directory where call segment timing information is.
    :param audio_conversion_cmd: (optional, str) command for converting audio files to format expected by Kaldi
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
        audio_id = file_name[:-4]
        # get subject id
        sub_id = id2sub[audio_id]
        # create recording id and write to wav.scp file
        rec_id = "{}_{}".format(sub_id, audio_id)
        write_line_to_wav(wav_scp_file, rec_id, audio_dir, file_name, audio_conversion_cmd)
        if segments_dir and segments_dir != "None":
            # need to get all segments in call and create a line for each of them in both utt2spk and segments files
            write_segment_lines(segments_out_file, file_name, utt2spk_file, rec_id, sub_id, segments_dir)
            segments_out_file.close()
        else:
            # if no segments dir, audio_id is segment_id and we can use rec_id as utt_id in utt2spk file
            out_line = ("{} {}\n".format(rec_id, sub_id))
            utt2spk_file.write(out_line)
    wav_scp_file.close()
    utt2spk_file.close()
    if segments_dir and segments_dir != "None":
        segments_out_file.close()


def prep_data_dirs(args, id2sub, group_file=None, audio_conversion_cmd=None):
    """
    :param args: Argument Parser argument with member variables corresponding to command line arguments.
    :param id2sub: Dict mapping ids used in naming audio files to subject ids.
    :param group_file: (optional) Open file to write the names of groups that data is split into to.
    :param audio_conversion_cmd: (optional str) command to use to convert audio files to format expected by Kaldi
    """
    # split data into groups if group_size is given and prepare directory for each group
    audio_file_names = os.listdir(args.audio_dir)
    # filter to only include files that are named *.wav
    audio_file_names = [f for f in audio_file_names if f[-4:] == ".wav"]
    if args.num_groups != 1:
        group_num = 0
        group_size = math.ceil(len(audio_file_names)/ args.num_groups)
        for i in range(0, len(audio_file_names), group_size):
            group_file_names = audio_file_names[i:i+group_size]
            group_out_dir = os.path.join(args.output_dir, "group_{}".format(group_num))
            prep_data_dir(group_out_dir, args.audio_dir, group_file_names, id2sub, args.segments_dir, audio_conversion_cmd)
            group_file.write("group_{}\n".format(group_num))
            group_num += 1
    else:
        prep_data_dir(args.output_dir, args.audio_dir, audio_file_names, id2sub, args.segments_dir, audio_conversion_cmd)


def main():
    # Read in and process command line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('-a', '--audio_dir', type=str, help='Directory containing audio wav files. It is assumed that '
                                                            'files are named call_id.wav if they contain full calls '
                                                            'and segment_id.wav if they contain segments of calls.')
    parser.add_argument('-o', '--output_dir', type=str, help='Data directory to output ASR prep files to')
    parser.add_argument('-s', '--segments_dir', type=str, help='Directory containing files with segment times'
                                                               'for each call audio file. Each each file in the '
                                                               'directory should be named call_id.txt and contain lines '
                                                               'of the form <segment_start> <segment_end> (in ms). ' 
                                                               '(only used if audio directory contains call rather than '
                                                               ' segment files)')
    parser.add_argument('-m', '--metadata_file_path', type=str, help='Path to text file containing mapping between audio file '
                                                                     'ids (i.e. call or segment ids) and subject ids. '
                                                                     'Each line should be of the form <audio_id> <subject_id>.')
    parser.add_argument('-g', '--num_groups', type=int, default=1, help='If not 1, will split data into <num_groups> groups'
                                                                        'and create a directory for each of them within the'
                                                                        'main data directory. This way the ASR model can be'
                                                                        'run and different portions of the data separately '
                                                                        '(may be necessary for really large datasets).')
    parser.add_argument('-c', '--convert_file_cmd', type=str, help='Command for converting audio files to WAV PCM format, '
                                                                   'which is expected by Kaldi. Optional, as files may already '
                                                                   'be in the correct format. Example command is: "sox {}  -t wav -r 8000 - |" '
                                                                   '(should include {} where audio file path should go).')

    args = parser.parse_args()

    # create dict mapping audio file ids to subject ids
    id2sub = {}
    with open(args.metadata_file_path, 'r') as f:
        for line in f:
            audio_id, subject_id = line.strip().split(" ")
            id2sub[audio_id] = subject_id

    # create file to write group names to if group_size is given
    group_file = None
    if args.num_groups != 1:
        group_file = open(os.path.join(args.output_dir, "group_names.txt"), 'w+')

    # get audio conversion command if provided
    audio_conversion_cmd = None
    if args.convert_file_cmd and args.convert_file_cmd != "None":
        audio_id = args.convert_file_cmd
    prep_data_dirs(args, id2sub, group_file, audio_conversion_cmd)

    group_file.close()


if __name__ == '__main__':
    main()
