function extract_vad_segs(minSegFactor)

addpath('/nfs/turbo/McInnisLab/Katie/data_processing_scripts/segment_extraction/Packages/Support', '/nfs/turbo/McInnisLab/Katie/data_processing_scripts/segment_extraction/Packages/Segments', '/nfs/turbo/McInnisLab/Libraries/voicebox');

filepath = '/nfs/turbo/McInnisLab/Katie/assessment_audio_copy/6840.wav';

[audio, Fs] = audioread(filepath);

[comboSignal, segParams] = extractComboSAD(audio, Fs);

Fss = segParams.Fss;

Segments = formContiguousSegments(comboSignal, minSegFactor*Fss, 0.8*Fss, 30*Fss);
Segments = resampleTimesAfterWindowing(Segments, segParams);

[splitSignal] = splitSignalBySegments(audio, Segments);
sigsize = size(splitSignal);
numsegs = sigsize(1);
for j = 1:numsegs
forms = '/nfs/turbo/McInnisLab/Katie/kaldi-5.2/egs/fisher_english/s5/data/segments_test/ms_%1.1f/6840_%d.wav';
outfilename = sprintf(forms, minSegFactor, j);
audiowrite(outfilename, splitSignal{j}, Fs);
end

exit;
