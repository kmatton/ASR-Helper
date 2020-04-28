function [ ] = removeSilenceSegments( inFilePath, outFilePath, vadThreshold, windowSize, stepSize )
%REMOVESILENCESEGMENTS - Remove silences from a speech file
%
% Syntax: removeSilenceSegments( inFilePath, outFilePath, vadThreshold, windowSize, stepSize )
%
% Inputs:
%    inFilePath (string) - Input speech file path
%    outFilePath (string) - Output speech file path
%    vadThreshold (scalar) - Threshold of segmentation signal to keep [default=1.5]
%    windowSize (scalar) - Size of the processing window [default=0.032*Fs]
%    stepSize (scalar) - Size of the processing steps [default=0.010*Fs]
%
% Examples (All Equivalent): 
%    extractComboSAD( '/dir/in.wav', '/dir/out.wav' )
%    extractComboSAD( '/dir/in.wav', '/dir/out.wav', 1.5 )
%    extractComboSAD( '/dir/in.wav', '/dir/out.wav', 1.5, 256, 80 )
%
% Other m-files required: extractComboSAD, resampleSignalAfterWindowing, 
%    enframe (from VOICEBOX toolbox)
% Subfunctions: none
% MAT-files required: none
%
% Author: John Gideon
% University of Michigan, Department of Computer Science and Engineering
% Email: gideonjn@umich.edu
% November 2015; Last revision: 24-November-2015
%
% See also: extractComboSAD, resampleSignalAfterWindowing

%------------- BEGIN CODE --------------

% Load file
[audio,Fs] = audioread(inFilePath);

% Check that window size exists
if ~exist('vadThreshold','var')
    vadThreshold = 1.5;
end

% Check that window size exists
if ~exist('windowSize','var')
    windowSize = 0.032*Fs;
end

% Check that window size exists
if ~exist('stepSize','var')
    stepSize = 0.010*Fs;
end

% Wrap code
[comboSignal, segParams] = extractComboSAD(audio, Fs, windowSize, stepSize);
vad = resampleSignalAfterWindowing(comboSignal, segParams);
vad = (vad-prctile(vad,5))./std(vad);
onlySpeech = audio(vad>=vadThreshold);
audiowrite(outFilePath,onlySpeech,Fs);

%------------- END OF CODE --------------