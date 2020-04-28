function get_seg_times(jobnum)

addpath('/nfs/turbo/McInnisLab/Katie/data_processing_scripts/segment_extraction/Packages/Support', '/nfs/turbo/McInnisLab/Katie/data_processing_scripts/segment_extraction/Packages/Segments', '/nfs/turbo/McInnisLab/Libraries/voicebox');

statusfilename = '/nfs/turbo/McInnisLab/Katie/priori_data/call_status_tracking/assess/call_status.csv';
opts = detectImportOptions(statusfilename);
opts.VariableTypes = {'double', 'double', 'logical', 'char'};
statustable = readtable(statusfilename, opts);

fid=fopen('/nfs/turbo/McInnisLab/Katie/priori_data/call_status_tracking/assess/priori_v1_calls_1_19.txt');
callfile = fgetl(fid);
callfilearr = cell(0,1);
while ischar(callfile)
    callfilearr{end+1,1} = callfile;
    callfile = fgetl(fid);
end
fclose(fid);

mkdir(sprintf('/nfs/turbo/McInnisLab/Katie/kaldi-5.2/egs/fisher_english/s5/data/assess/set_%d', jobnum));
formatspec = '/nfs/turbo/McInnisLab/Katie/kaldi-5.2/egs/fisher_english/s5/data/assess/set_%d/segments';
filestr = sprintf(formatspec, jobnum);
outfileid = fopen(filestr, 'w+');
wav_formatspec = '/nfs/turbo/McInnisLab/Katie/kaldi-5.2/egs/fisher_english/s5/data/assess/set_%d/wav.scp';
wav_filestr = sprintf(wav_formatspec, jobnum);
wav_fileid = fopen(wav_filestr, 'w+');
u_fs = '/nfs/turbo/McInnisLab/Katie/kaldi-5.2/egs/fisher_english/s5/data/assess/set_%d/utt2spk';
u_filestr = sprintf(u_fs, jobnum);
u_fileid = fopen(u_filestr, 'w+');

startidx = jobnum * 100 + 1;
endidx = startidx + 100 - 1;
if endidx > 1522
    endidx = 1522;
end

for callnum=startidx:endidx
    callfilename = callfilearr{callnum};
    sid = statustable{callnum, 'subject_id'};
    week_num = statustable{callnum, 'week_number'};

    audiospec = '/nfs/turbo/McInnisLab/Katie/assess_audio/%s';
    filepath = sprintf(audiospec, callfilename);
    try
        [audio, Fs] = audioread(filepath);
        [comboSignal, segParams] = extractComboSAD(audio, Fs);

        Fss = segParams.Fss;

        Segments = formContiguousSegments(comboSignal, 0.3*Fss, 0.8*Fss, 30*Fss);
        Segments = resampleTimesAfterWindowing(Segments, segParams);
    catch ME
        fprintf('Error: %s\n', ME.message);
        fprintf('file is %s\n', filepath);
        statustable{callnum, 'segments_extracted_'} = false;
        statustable{callnum, 'extraction_error'} = {ME.message};
        continue;
    end;

    statustable{callnum, 'segments_extracted_'} = true;
        
    startTimes = Segments.Start / Fs;
    endTimes = Segments.Stop / Fs;
    numtimes = size(startTimes, 1);

    uttSpec = '%s_%s_%s_%s';
    recSpec = '%s_%s';
    recStr = sprintf(recSpec, int2str(sid), int2str(week_num));
    wav_fs = '%s %s\n';

    for j = 1:numtimes
        formatSpec = '%s %s %0.5f %0.5f\n';
        utt_fs = '%s %s\n';
        startStr = int2str(round(startTimes(j) * 100));
        endStr = int2str(round(endTimes(j) * 100));
        uttStr = sprintf(uttSpec, int2str(sid), int2str(week_num), startStr, endStr);
        fprintf(outfileid, formatSpec, uttStr, recStr, startTimes(j), endTimes(j));
        fprintf(u_fileid, utt_fs, uttStr, int2str(sid));
    end
    if numtimes > 0
        fprintf(wav_fileid, wav_fs, recStr, filepath);
    else
        statustable{callnum, 'segments_extracted_'} = false;
        statustable{callnum, 'extraction_error'} = {'number of segments found was 0'};
    end
end
fclose(outfileid);
fclose(wav_fileid);
fclose(u_fileid);
del_rows_b = 1:startidx - 1;
del_rows_e = endidx+1:1522;
statustable(horzcat(del_rows_b, del_rows_e),:) = [];
writetable(statustable, sprintf('/nfs/turbo/McInnisLab/Katie/priori_data/call_status_tracking/assess/call_status_%d.csv', jobnum), 'Delimiter', ',');

exit;


