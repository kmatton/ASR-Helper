
function num_missed = getRemainSegs(start_idx, end_idx, seg_num) 

addpath('/nfs/turbo/McInnisLab/Katie/data_processing_scripts/segment_extraction/Packages/Support', '/nfs/turbo/McInnisLab/Katie/data_processing_scripts/segment_extraction/Packages/Segments', '/nfs/turbo/McInnisLab/Libraries/voicebox');
infileid = fopen('/nfs/turbo/McInnisLab/Katie/assessment_audio_metadata/seg_check_sort.txt', 'r');
formatSpec = '/nfs/turbo/McInnisLab/Katie/assessment_audio_metadata/segments%d.txt';
formatErrorSpec = '/nfs/turbo/McInnisLab/Katie/assessment_audio_metadata/seg_errors%d.txt';
errorfilename = sprintf(formatErrorSpec, seg_num);
errorfileid = fopen(errorfilename, 'w+');
outfilename = sprintf(formatSpec, seg_num);
outfileid = fopen(outfilename, 'w+');
tline = fgetl(infileid);
tlines = cell(0,1);
while ischar(tline)
    tlines{end+1, 1} = tline;
    tline = fgetl(infileid);
end
fclose(infileid);
num_missed = 0;
for i = start_idx:end_idx
	arr = strsplit(char(tlines(i)), '\t');
        filename = char(arr(2));
	formatSpec = '/nfs/turbo/McInnisLab/Katie/assessment_audio_copy/%s';
	filestr = sprintf(formatSpec, filename);
	try
		[audio, Fs] = audioread(filestr);

		[comboSignal, segParams] = extractComboSAD(audio, Fs);

		Fss = segParams.Fss;

		Segments = formContiguousSegments(comboSignal, 2*Fss, 0.8*Fss, 30*Fss);
		Segments = resampleTimesAfterWindowing(Segments, segParams);
	catch ME
		fprintf(errorfileid, 'Error: %s\n', ME.message);
		fprintf(errorfileid, 'file is %s\n', filestr);
                num_missed = num_missed + 1;
		continue;
	end;
	
	startTimes = Segments.Start / Fs;
	endTimes = Segments.Stop / Fs;
	numtimes = size(startTimes, 1);
	for j = 1:numtimes
		formatSpec = '%s\t%0.5f\t%0.5f\n';
		fprintf(outfileid, formatSpec, filename, startTimes(j), endTimes(j));
	end	
end
fclose(outfileid);
