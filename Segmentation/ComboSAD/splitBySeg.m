
function num_split = splitBySeg(job_num)

addpath('/nfs/turbo/McInnisLab/Katie/data_processing_scripts/segment_extraction/Packages/Support', '/nfs/turbo/McInnisLab/Katie/data_processing_scripts/segment_extraction/Packages/Segments', '/nfs/turbo/McInnisLab/Libraries/voicebox');
num_split = 0;
errorfilename = '/nfs/turbo/McInnisLab/Katie/assessment_audio_metadata/seg_split_errors.txt';
errorfileid = fopen(errorfilename, 'a+');

audiofileFSpec = '/nfs/turbo/McInnisLab/Katie/assessment_audio_copy/%s';

filenum_strs = ['0', '1', '10', '10b', '11', '12', '13', '14', '15', '16', '17', '18', '19', '1b', '2', '20', '21', '3','4', '4b', '5', '5b', '6', '6b', '7', '8', '8b', '9'];
numfiles = size(filenum_strs);
sec_size = ceil(numfiles/10);
start_idx = sec_size * job_num + 1;
end_idx = start_idx + sec_size - 1;
if numfiles > end_idx
    end_idx = numfiles
end
for i = start_idx:end_idx
        formatSpec = '/nfs/turbo/McInnisLab/Katie/assessment_audio_metadata/segments%s.txt';
        filestr = sprintf(formatSpec, filenum_strs(i));
        infileid = fopen(filestr, 'r');
        tline = fgetl(infileid);
        line_cell_arr = strsplit(tline, '\t');
        curr_file = line_cell_arr{1};
        curr_Segs = cell(0, 2);
        while ischar(tline)
            line_cell_arr = strsplit(tline, '\t');
            curr_Segs{end+1, 2} = line_cell_arr{1, 2:3};
            tline = fgetl(infileid);
            lc_arr = strsplit(tline, '\t');
            if lc_arr{1} ~= curr_file
                % segments for current file fully collected
                audiofilename = sprintf(audiofileFSpec, curr_file);
                [audio, Fs] = audioread(audiofilename)
                [splitSignal] = splitSignalBySegments(audio, curr_Segs);
                sigsize = size(splitSignal);
                numsegs = sigsize(1);
                call_num = curr_file(1:end-4)
                for i = 1:numsegs
                    fSpec = '/nfs/turbo/McInnisLab/Katie/assess_audio_segments/%s_%d.wav';
                    outfilename = sprintf(fSpec, curr_num, i);
                    audiowrite(outfilename, splitSignal{i}, Fs);
                end
                curr_file = lc_arr{1};
                curr_Segs = cell(0, 2);
            end
        end
end
