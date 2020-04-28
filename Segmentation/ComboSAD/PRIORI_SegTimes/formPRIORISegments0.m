
%function num_missed = splitToSegs(job_num)

filelist = dir('/nfs/turbo/McInnisLab/Katie/assessment_audio_copy');
numfiles = size(filelist, 1);
num_missed = 0;
formatErrorSpec = '/nfs/turbo/McInnisLab/Katie/assessment_audio_metadata/seg_split_errors.txt';
errorfilename = sprintf(formatErrorSpec, seg_num);
errorfileid = fopen(errorfilename, 'w+');
sec_size = ceil(numfiles/10);
start_idx = sec_size * job_num + 1;
end_idx = start_idx + sec_size - 1;
if numfiles > end_idx
    end_idx = numfiles
end 
for i = start_idx:end_idx
	formatSpec = '/nfs/turbo/McInnisLab/Katie/assessment_audio_copy/%s';
	filestr = sprintf(formatSpec, filelist(i).name);
	
	try
		[audio, Fs] = audioread(filestr);

		[comboSignal, segParams] = extractComboSAD(audio, Fs);

		Fss = segParams.Fss;

		Segments = formContiguousSegments(comboSignal, 2*Fss, 0.8*Fss, 30*Fss);
		Segments = resampleTimesAfterWindowing(Segments, segParams);
	catch ME
                fprintf(errorfileid, 'ERROR in job number %d\n', job_num);
                fprintf(errorfileid, 'Error: %s\n', ME.message);
                fprintf(errorfileid, 'file is %s\n\n', filestr);
                num_missed = num_missed + 1;
                continue;
	end;
	
	startTimes = Segments.Start / Fs;
        endTimes = Segments.Stop / Fs;
        [splitSignal] = splitSignalBySegments(audio, Segments);
        sigsize = size(splitSignal);
        numsegs = sigsize(1);
        for i = 1:numsegs
            % update name of file and location of file that gets created
            % also maybe generate metadata as you go?
            formatSpec = '/nfs/turbo/McInnisLab/Katie/assessment_audio_metadata/testseg%d.wav';
            outfilename = sprintf(formatSpec, i);
            audiowrite(outfilename, splitSignal{i}, Fs);
        end	
end
