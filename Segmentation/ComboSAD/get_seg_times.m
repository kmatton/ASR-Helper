function get_seg_times(setnum)

addpath('/nfs/turbo/McInnisLab/Katie/data_processing_scripts/segment_extraction/Packages/Support', '/nfs/turbo/McInnisLab/Katie/data_processing_scripts/segment_extraction/Packages/Segments', '/nfs/turbo/McInnisLab/Libraries/voicebox');

filelist = dir('/nfs/turbo/McInnisLab/Katie/assessment_audio_copy');
metafilename = '/home/katiemat/metadata/assess/assessment_metadata.txt';
opts = detectImportOptions(metafilename);
opts.RowNamesColumn = 5;
opts.VariableTypes = {'char', 'char', 'datetime', 'char', 'char', 'double', 'double', 'char', 'char', 'char', 'char'};
metatable = readtable(metafilename, opts);

startidx = setnum * 100 + 3;
endidx = startidx + 100 - 1;
if endidx > 1288
    endidx = 1288;
end
for callnum=startidx:endidx
    filename = filelist(callnum).name; % 3-1288
    filesplit = strsplit(filename, '.');
    callid = filesplit{1};
    sid = metatable{callid, 'subject_id'}{1};

    mkdir(sprintf('/nfs/turbo/McInnisLab/Katie/kaldi-5.2/egs/fisher_english/s5/data/assess/%s', callid));
    formatspec = '/nfs/turbo/McInnisLab/Katie/kaldi-5.2/egs/fisher_english/s5/data/assess/%s/segments';
    filestr = sprintf(formatspec, callid);
    outfileid = fopen(filestr, 'w+');

    audiospec = '/nfs/turbo/McInnisLab/Katie/assessment_audio_copy/%s.wav';
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

    uttSpec = '%s_%s_%s_%s';
    recSpec = '%s_%s';

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


