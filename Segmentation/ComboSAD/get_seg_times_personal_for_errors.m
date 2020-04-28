addpath('/nfs/turbo/McInnisLab/Katie/data_processing_scripts/segment_extraction/Packages/Support', '/nfs/turbo/McInnisLab/Katie/data_processing_scripts/segment_extraction/Packages/Segments', '/nfs/turbo/McInnisLab/Libraries/voicebox');

metafilename = '/home/katiemat/metadata/personal/all_metadata.txt';
opts = detectImportOptions(metafilename);
opts.VariableTypes = {'char', 'char', 'char', 'double', 'double', 'datetime', 'double', 'char'};
opts.RowNamesColumn = 1;
metatable = readtable(metafilename, opts);

callfilename = '/nfs/turbo/McInnisLab/Katie/PRIORI_transcripts/processing_scripts/personal_do_undefined_errors.txt';
callfileid = fopen(callfilename, 'r');
callFS = '%d';
callarr = fscanf(callfileid, callFS);

for callnum=1:11
    callid = callarr(callnum);
    fprintf('Working on call: %d\n', callid);
    callfileFS = '%d.wav';
    filename = sprintf(callfileFS, callid);
    sid = metatable{int2str(callid), 'subject_id'}{1};

    mkdir(sprintf('/nfs/turbo/McInnisLab/Katie/kaldi-5.2/egs/fisher_english/s5/data/personal/%d', callid));
    formatspec = '/nfs/turbo/McInnisLab/Katie/kaldi-5.2/egs/fisher_english/s5/data/personal/%d/segments';
    filestr = sprintf(formatspec, callid);
    outfileid = fopen(filestr, 'w+');

    audiospec = '/nfs/turbo/McInnisLab/Katie/call_audio/speech/%d.wav';
    filepath = sprintf(audiospec, callid);
    try
        [audio, Fs] = audioread(filepath);
        [comboSignal, segParams] = extractComboSAD(audio, Fs);

        Fss = segParams.Fss;

        Segments = formContiguousSegments(comboSignal, 0.3*Fss, 0.8*Fss, 30*Fss);
        Segments = resampleTimesAfterWindowing(Segments, segParams);
    catch ME
		fprintf('Error: %s\n', ME.message);
		fprintf('file is %s\n', filestr);
		continue;
	end;
        
    startTimes = Segments.Start / Fs;
    endTimes = Segments.Stop / Fs;
    numtimes = size(startTimes, 1);

    uttSpec = '%s_%d_%s_%s';
    recSpec = '%s_%d';

    fprintf('Number of segments: %d\n', numtimes);

    for j = 1:numtimes
        formatSpec = '%s %s %0.5f %0.5f\n';
        startStr = int2str(round(startTimes(j) * 100));
        endStr = int2str(round(endTimes(j) * 100));
        uttStr = sprintf(uttSpec, sid, callid, startStr, endStr);
        recStr = sprintf(recSpec, sid, callid);
        fprintf(outfileid, formatSpec, uttStr, recStr, startTimes(j), endTimes(j));
    end	

    fclose(outfileid);
end

exit;


