
function num_errors = getAudioSegs(job_num)

addpath('/nfs/turbo/McInnisLab/Katie/data_processing_scripts/segment_extraction/Packages/Support', '/nfs/turbo/McInnisLab/Katie/data_processing_scripts/segment_extraction/Packages/Segments', '/nfs/turbo/McInnisLab/Libraries/voicebox');

filelist = dir('/nfs/turbo/McInnisLab/Katie/assessment_audio_copy');

errorFS = '/nfs/turbo/McInnisLab/Katie/assess_audio_segments/seg_split_errors_%d.txt';
errorfilename = sprintf(errorFS, job_num);
errorfileid = fopen(errorfilename, 'a+');
fid = fopen('/nfs/turbo/McInnisLab/Katie/assess_audio_segments/missing_files.txt', 'r');
tline = fgetl(fid);
indices = cell(0,1);
while ischar(tline)
    line_cell_arr = strsplit(tline, '\t');
    indices{end+1, 1} = line_cell_arr{1, 1};
    tline = fgetl(fid);
end
numfiles = 129;
sec_size = ceil(numfiles/2);
start_idx = sec_size * job_num + 1;
end_idx = start_idx + sec_size - 1;
if end_idx > numfiles
    end_idx = numfiles
end
for i = start_idx:end_idx
    formatSpec = '/nfs/turbo/McInnisLab/Katie/assessment_audio_copy/%s';
    index = str2num(indices{i, 1});
    filestr = sprintf(formatSpec, filelist(index).name);
    call_num = filelist(index).name(1:end-4);
    try
        [audio, Fs] = audioread(filestr);

        [comboSignal, segParams] = extractComboSAD(audio, Fs);

        Fss = segParams.Fss;

        Segments = formContiguousSegments(comboSignal, 2*Fss, 0.8*Fss, 30*Fss);
        Segments = resampleTimesAfterWindowing(Segments, segParams);
    catch ME
        error_spec1 = 'Extracting segment times failed for file %s\n';
        error_spec2 = 'Error: %s\n\n';
        fprintf(errorfileid, error_spec1, call_num);
        fprintf(errorfileid, error_spec2, ME.message);
        continue;
    end;
    try
        [splitSignal] = splitSignalBySegments(audio, Segments);
        sigsize = size(splitSignal);
        numsegs = sigsize(1);
        for j = 1:numsegs
	    forms = '/nfs/turbo/McInnisLab/Katie/assess_audio_segments/%s_%d.wav';
	    outfilename = sprintf(forms, call_num, j);
	    audiowrite(outfilename, splitSignal{j}, Fs);
        end
    catch ME
        error_spec3 = 'Splitting signal failed for file %s\n';
        error_spec4 = 'Error: %s\n\n';
        fprintf(errorfileid, error_spec3, call_num);
        fprintf(errorfileid, error_spec4, ME.message);
    end;
end
