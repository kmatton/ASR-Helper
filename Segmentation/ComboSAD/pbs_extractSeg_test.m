
function num_errors = pbs_extractSeg_test(job_num)

addpath('/nfs/turbo/McInnisLab/Katie/data_processing_scripts/segment_extraction/Packages/Support', '/nfs/turbo/McInnisLab/Katie/data_processing_scripts/segment_extraction/Packages/Segments', '/nfs/turbo/McInnisLab/Libraries/voicebox');

filelist = dir('/nfs/turbo/McInnisLab/Katie/call_audio/speech');

errorFS = '/home/katiemat/errors/NA_seg_%d.txt';
errorfilename = sprintf(errorFS, job_num);
errorfileid = fopen(errorfilename, 'a+');

numfiles = size(filelist, 1);
sec_size = ceil(numfiles/100);
start_idx = sec_size * job_num + 1;
if start_idx < 3
    start_idx = 3;
end
end_idx = start_idx + sec_size - 1;
if end_idx > numfiles
    end_idx = numfiles;
end
start_idx = 4;
end_idx = 4;
for i = start_idx:end_idx
    disp('entered loop');
    filestr = filelist(i).name;
    call_num = filestr(1:end-4);
    filepathFS = '/nfs/turbo/McInnisLab/Katie/call_audio/speech/%s';
    filepath = sprintf(filepathFS, filestr);
    try

        [audio, Fs] = audioread(filepath);

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
	    forms = '/nfs/turbo/McInnisLab/Katie/call_audio_segments/set%d/%s_%d.wav';
	    outfilename = sprintf(forms, job_num, call_num, j);
	    audiowrite(outfilename, splitSignal{j}, Fs);
        end
    catch ME
        error_spec3 = 'Splitting signal failed for file %s\n';
        error_spec4 = 'Error: %s\n\n';
        fprintf(errorfileid, error_spec3, call_num);
        fprintf(errorfileid, error_spec4, ME.message);
    end;
end

exit;
