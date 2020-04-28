addpath('/nfs/turbo/McInnisLab/Katie/data_processing_scripts/segment_extraction/Packages/Support', '/nfs/turbo/McInnisLab/Katie/data_processing_scripts/segment_extraction/Packages/Segments', '/nfs/turbo/McInnisLab/Libraries/voicebox');

inputstr = '/nfs/turbo/McInnisLab/Katie/assessment_audio_copy/1004.wav';
[audio, Fs] = audioread(inputstr);

[comboSignal, segParams] = extractComboSAD(audio, Fs);

Fss = segParams.Fss;

Segments = formContiguousSegments(comboSignal, 2*Fss, 0.8*Fss, 30*Fss);
Segments = resampleTimesAfterWindowing(Segments, segParams);
disp('got segments');
startTimes = Segments.Start / Fs;
endTimes = Segments.Stop / Fs;
[splitSignal] = splitSignalBySegments(audio, Segments);
sigsize = size(splitSignal);
numsegs = sigsize(1);
for i = 1:numsegs
	formatSpec = '/nfs/turbo/McInnisLab/Katie/assessment_audio_metadata/NEWtestseg%d.wav';
	outfilename = sprintf(formatSpec, i);
	audiowrite(outfilename, splitSignal{i}, Fs);
end

