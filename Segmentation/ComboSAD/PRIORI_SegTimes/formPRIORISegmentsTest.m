
addpath('/nfs/turbo/McInnisLab/Katie/data_processing_scripts/segment_extraction/Packages/Support', '/nfs/turbo/McInnisLab/Katie/data_processing_scripts/segment_extraction/Packages/Segments', '/nfs/turbo/McInnisLab/Libraries/voicebox');
filelist = dir('/nfs/turbo/McInnisLab/Katie/assessment_audio_copy');
numfiles = size(filelist, 1);

outfileid = fopen('/nfs/turbo/McInnisLab/Katie/assessment_audio_metadata/segments_my_test.txt', 'w+');

for i = 3:3
	% goes to 133
	formatSpec = '/nfs/turbo/McInnisLab/Katie/assessment_audio_copy/%s';
	filestr = sprintf(formatSpec, filelist(i).name);
	
	try
		[audio, Fs] = audioread(filestr);

		[comboSignal, segParams] = extractComboSAD(audio, Fs);

		Fss = segParams.Fss;

		Segments = formContiguousSegments(comboSignal, 2*Fss, 0.8*Fss, 30*Fss);
		Segments = resampleTimesAfterWindowing(Segments, segParams);
	catch ME
		fprintf('Error: %s\n', ME.message);
		fprintf('file is %s\n', filestr);
		continue;
	end;
	
	startTimes = Segments.Start / Fs;
	endTimes = Segments.Stop / Fs;
	numtimes = size(startTimes, 1);
	for j = 1:numtimes
		formatSpec = '%s\t%0.5f\t%0.5f\n';
		fprintf(outfileid, formatSpec, filelist(i).name, startTimes(j), endTimes(j));
	end	
end
fclose(outfileid);
