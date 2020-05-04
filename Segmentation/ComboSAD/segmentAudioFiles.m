function segmentAudioFiles(audioDir, outputDir, nj, writeAudio)
% SEGMENTAUDIOFILES - Segment audio files into regions of continuous speech using the ComboSAD algorithm.
% Creates segments.txt file in outputDir that has one line per segment of the form:
% <callID> <segment start> <segment end> <path to segment wav file(if writeAudio is true)>
% callID is assumed to be the name of the file in audioDir that segment was extracted from.
%
% Syntax: segmentAudioFiles(audioDir, outputDir, writeAudio)
%
% Inputs:
%    audioDir (str) - Path to directory where audio files are located.
%                     Audio files are expected to be wav files ending with .wav.
%    outputDir (dir) - Path to directory to output segments to.
%    nj (int) - Number of jobs to use in executing segment extraction.
%    writeAudio (bool)- If true, write segments to audio files in outputDir. 
%                       Otherwise, only record start and end times of segments. 
%
% Other m-files required: extractComboSAD, formContiguousSegments, resampleSignalAfterWindowing, 
%     splitSignalBySegments, enframe (from VOICEBOX toolbox)
% Subfunctions: segmentAudioFile
% MAT-files required: none

%------------- BEGIN CODE --------------

audioFiles = dir(audioDir, '*.wav');
numFiles = length(audioFiles);

allStartTimes = cell(numFiles);
allEndTimes = cell(numFiles);
allSegFilePaths = cell(numFiles);
allCallIDs = cell(numFiles);

% segment each audio file and save metadata info
parpool(nj);
parfor i=1:numFiles
    audioFileName = audioFiles(i);
    audioFilePath = fullfile(audioDir, audioFileName);
    [segStartTimes, segEndTimes, segFilePaths] = segmentAudioFile(audioFilePath, outputDir, writeAudio);
    allStartTimes{i} = segStartTimes;
    allEndTimes{i} = segEndTimes;
    allSegFilePaths{i} = segFilePaths;
    callID, _ = fileparts(audioFileName);
    numSegs = length(segStartTimes);
    segCallIDs = repelem(callID, numSegs);
    allCallIDs{i} = segCallIDs;
end

% flatten segment cell arrays
allStartTimes = [allStartTimes{:}];
allEndTimes = [allEndTimes{:}];
allSegFilePaths = [allSegFilePaths{:}];
allCallIDs = [allCallIDs{:}];

% create segments.txt file with info about segments
outputFileName = 'segments.txt';
outFileID = fopen(fullfile(outputDir, outputFileName), 'w');
numSegs = length(allStartTimes);
for i = 1:numSegs
    callID = allCallIDs(i);
    segStart = allStartTimes(i);
    segEnd = allStartTimes(i);
    if writeAudio
        segFormat = '%s_%s_%s_%s\n';
        segFilePath = allSegFilePaths(i);
        fprintf(outFileID, segFormat, callID, segStart, segEnd, segFilePath);
    else
        segFormat = '%s_%s_%s\n';
        fprintf(outFileID, segFormat, callID, segStart, segEnd);
    end
end
    
%------------- END OF CODE --------------

function [segStartTimes, segEndTimes, segFilePaths] = segmentAudioFile(audioFilePath, outputDir, writeAudio)
% SEGMENTAUDIOFILE - Segment single audio file into regions of continuous speech using the ComboSAD algorithm.
% Helper function for segmentAudioFiles
%
% Syntax: [segStartTimes, segEndTimes, segFilePaths] = segmentAudioFile(audio, outputDir, writeAudio)
%
% Inputs:
%    audioFilePath - Path to audio file to segment.
%    outputDir (string) - Path to directory to write segment audio to (ignored if writeAudio is false).
%    writeAudio (bool) - If true, write audio for each segment to a wav file.
%
% Outputs:
%    segStartTimes (list of scalars) - List of start times for each segment.
%    segEndTimes (list of scalaras) - List of end times for each segment.
%    segFilePaths (list of strings) - Each string is path to wav file created for single segment.
%                     
%
% Other m-files required: extractComboSAD, formContiguousSegments, resampleSignalAfterWindowing, 
%     splitSignalBySegments, enframe (from VOICEBOX toolbox)
% Subfunctions: none
% MAT-files required: none

%------------- BEGIN CODE --------------

% try to segment audio file
 try
    [audio, Fs] = audioread(audioFilePath);
    [comboSignal, segParams] = extractComboSAD(audio, Fs);

    Fss = segParams.Fss;

    Segments = formContiguousSegments(comboSignal, 0.3*Fss, 0.8*Fss, 30*Fss);
    Segments = resampleTimesAfterWindowing(Segments, segParams);
catch ME
    fprintf('Error: %s for audio file %s\n', ME.message, audioFilePath);
    segStartTimes = [];
    segEndTimes = [];
    segFilePaths = [];
    return;
end;
    
startTimes = Segments.Start / Fs;
endTimes = Segments.Stop / Fs;
segFilePaths = [];

% if writeAudio, write segment audio to files
if writeAudio
    outFileFormat = '%s_%s_%s.wav';
    _, callID, _ = fileparts(audioFilePath);
    [splitSignal] = splitSignalBySegments(audio, Segments);
    sigsize = size(splitSignal);
    numsegs = sigsize(1);
    for i = 1:numsegs
        segStartStr = int2str(round(startTimes(i) * 100));
        segEndStr = int2str(round(endTimes(i) * 100));
        outFileName = sprintf(outFileFormat, callID, segStartStr, SegEndStr);
        audiowrite(outFileName, splitSignal{i}, Fs);
    end
end

%------------- END OF CODE --------------
