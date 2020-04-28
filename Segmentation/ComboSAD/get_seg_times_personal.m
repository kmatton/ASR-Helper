function get_seg_times(jobnum)

addpath('/nfs/turbo/McInnisLab/Katie/data_processing_scripts/segment_extraction/Packages/Support', '/nfs/turbo/McInnisLab/Katie/data_processing_scripts/segment_extraction/Packages/Segments', '/nfs/turbo/McInnisLab/Libraries/voicebox');

metafilename = '/home/katiemat/metadata/personal/personal_all_calls_metadata.csv';
opts = detectImportOptions(metafilename);
opts.VariableTypes = {'char', 'double', 'double', 'char', 'datetime', 'datetime', 'char', 'char', 'char'};
opts.RowNamesColumn = 1;
metatable = readtable(metafilename, opts);
callarr = metatable.callid;

succfilename = '/nfs/turbo/McInnisLab/Katie/kaldi-5.2/egs/fisher_english/s5/data/personal/seg_success_pids.txt';
succfileid = fopen(succfilename, 'r');
succFS = '%d';
succcallarr = fscanf(succfileid, succFS);

startidx = jobnum * 290 + 1;
endidx = startidx + 290 - 1;
if endidx > 29043
    endidx = 29043;
end
for set=1:29
    if startidx > endidx
        break
    end
    set_num = jobnum * 29 + set + 2929;
    mkdir(sprintf('/nfs/turbo/McInnisLab/Katie/kaldi-5.2/egs/fisher_english/s5/data/personal/set_%d', set_num));
    formatspec = '/nfs/turbo/McInnisLab/Katie/kaldi-5.2/egs/fisher_english/s5/data/personal/set_%d/segments';
    filestr = sprintf(formatspec, set_num);
    outfileid = fopen(filestr, 'w+');
    wav_formatspec = '/nfs/turbo/McInnisLab/Katie/kaldi-5.2/egs/fisher_english/s5/data/personal/set_%d/wav.scp';
    wav_filestr = sprintf(wav_formatspec, set_num);
    wav_fileid = fopen(wav_filestr, 'w+');
    u_fs = '/nfs/turbo/McInnisLab/Katie/kaldi-5.2/egs/fisher_english/s5/data/personal/set_%d/utt2spk';
    u_filestr = sprintf(u_fs, set_num);
    u_fileid = fopen(u_filestr, 'w+');
    end_set_idx = startidx + 9;
    if end_set_idx > endidx
        end_set_idx = endidx;
    end
    for callnum=startidx:end_set_idx
        callid = callarr{callnum};
        if ismember(str2num(callid), succcallarr)
            continue;
        end
        sid = metatable.sid{callid};

        audiospec = '/nfs/turbo/McInnisLab/Katie/call_audio/speech/%s.wav';
        filepath = sprintf(audiospec, callid);
        try
            [audio, Fs] = audioread(filepath);
            [comboSignal, segParams] = extractComboSAD(audio, Fs);

            Fss = segParams.Fss;

            Segments = formContiguousSegments(comboSignal, 0.3*Fss, 0.8*Fss, 30*Fss);
            Segments = resampleTimesAfterWindowing(Segments, segParams);
        catch ME
            fprintf('Error: %s\n', ME.message);
            fprintf('file is %s\n', filepath);
            continue;
        end;
            
        startTimes = Segments.Start / Fs;
        endTimes = Segments.Stop / Fs;
        numtimes = size(startTimes, 1);

        uttSpec = '%s_%s_%s_%s';
        recSpec = '%s_%s';

        for j = 1:numtimes
            formatSpec = '%s %s %0.5f %0.5f\n';
            wav_fs = '%s %s\n';
            utt_fs = '%s %s\n';
            startStr = int2str(round(startTimes(j) * 100));
            endStr = int2str(round(endTimes(j) * 100));
            uttStr = sprintf(uttSpec, sid, callid, startStr, endStr);
            recStr = sprintf(recSpec, sid, callid);
            fprintf(outfileid, formatSpec, uttStr, recStr, startTimes(j), endTimes(j));
            fprintf(wav_fileid, wav_fs, recStr, filepath);
            fprintf(u_fileid, utt_fs, uttStr, sid);
        end	
    end
    fclose(outfileid);
    startidx=callnum+1;
end

exit;


