
addpath('/nfs/turbo/McInnisLab/Katie/data_processing_scripts/segment_extraction/Packages/Support', '/nfs/turbo/McInnisLab/Katie/data_processing_scripts/segment_extraction/Packages/Segments', '/nfs/turbo/McInnisLab/Libraries/voicebox');


audiofileFSpec = '/nfs/turbo/McInnisLab/Katie/assessment_audio_copy/%s';

filestr = '/nfs/turbo/McInnisLab/Katie/assessment_audio_metadata/segments0.txt';
infileid = fopen(filestr, 'r');
tline = fgetl(infileid);
line_cell_arr = strsplit(tline, '\t');
prev_file = line_cell_arr{1};
curr_file = line_cell_arr{1};
curr_Starts = [];
curr_Ends = [];
while ischar(tline)
    while strcmp(curr_file,prev_file)
        curr_Starts(end + 1) = str2double(line_cell_arr{1, 2});
        curr_Ends(end + 1) = str2double(line_cell_arr{1, 3});
        tline = fgetl(infileid);
        if ischar(tline)
            line_cell_arr = strsplit(tline, '\t');
            curr_file = line_cell_arr{1};
        else
            curr_file = '';
        end
    end
    % segments for prev file completely collected
    audiofilename = sprintf(audiofileFSpec, prev_file);
    [audio, Fs] = audioread(audiofilename);
    Segments = struct();
    Segments.Start = Fs * curr_Starts(:);
    Segments.Stop = Fs * curr_Ends(:);
    Segments = struct2table(Segments);
    disp(Segments);
    [splitSignal] = splitSignalBySegments(audio, Segments);
    sigsize = size(splitSignal);
    numsegs = sigsize(1);
    call_num = prev_file(1:end-4)
    for i = 1:numsegs
        fSpec = '/nfs/turbo/McInnisLab/Katie/assess_audio_segments/%s_%d.wav';
        outfilename = sprintf(fSpec, call_num, i);
        audiowrite(outfilename, splitSignal{i}, Fs);
    end
    prev_file = curr_file;
    curr_Starts = [];
    curr_Ends = [];
end

