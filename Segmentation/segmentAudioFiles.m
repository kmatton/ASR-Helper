function segmentAudioFiles(audioDir, outputDir, nj, writeAudio, voiceBoxPath, errorPath)
% SEGMENTAUDIOFILES - Segment audio files into regions of continuous speech using the ComboSAD algorithm.
% Creates segments.txt file in outputDir that has one line per segment of the form:
% <callID> <segment start> <segment end> <path to segment wav file(if writeAudio is true)>
% callID is assumed to be the name of the file in audioDir that segment was extracted from.
%
% Syntax: segmentAudioFiles(audioDir, outputDir, writeAudio, voiceBoxPath, errorPath)
%
% Inputs:
%    audioDir (str) - Path to directory where audio files are located.
%                     Audio files are expected to be wav files ending with .wav.
%    outputDir (dir) - Path to directory to output segments to.
%    nj (int) - Number of jobs to use in executing segment extraction.
%    writeAudio (bool)- If true, write segments to audio files in outputDir. 
%                       Otherwise, only record start and end times of segments. 
%    voiceBoxPath (str) - Path to directory where VOIECEBOX toolbox is stored.
%    errorPath (str) - Path to text file to record calls where segmentation failed.
%
% Other m-files required: extractComboSAD, formContiguousSegments, resampleSignalAfterWindowing, 
%     splitSignalBySegments, enframe (from VOICEBOX toolbox)
% Subfunctions: segmentAudioFile
% MAT-files required: none

%------------- BEGIN CODE --------------

addpath('./ComboSAD', './Support', './Segments', voiceBoxPath);

% create output directory if it doesn't exist
if ~exist(outputDir, 'dir')
    mkdir(outputDir)
end 

audioFiles = dir(fullfile(audioDir, '*.wav'));
numFiles = length(audioFiles);

allStartTimes = cell(numFiles, 1);
allEndTimes = cell(numFiles, 1);
allSegFilePaths = cell(numFiles, 1);
allCallIDs = cell(numFiles, 1);

errorFileID = fopen(errorPath, 'w');

% segment each audio file and save metadata info
%parpool(nj);
for i = 1:numFiles
    audioFileName = audioFiles(i).name;
    audioFilePath = fullfile(audioDir, audioFileName);
    [segStartTimes, segEndTimes, segFilePaths] = segmentAudioFile(audioFilePath, outputDir, writeAudio, errorFileID);
    allStartTimes{i} = segStartTimes;
    allEndTimes{i} = segEndTimes;
    allSegFilePaths{i} = segFilePaths;
    [~,callID,~] = fileparts(audioFilePath);
    numSegs = length(segStartTimes);
    [callIDs{1:numSegs}] = deal(callID);
    allCallIDs{i} = callIDs;
end

fclose(errorFileID);

% flatten segment cell arrays
allStartTimes = [allStartTimes{:}];
allEndTimes = [allEndTimes{:}];
allSegFilePaths = [allSegFilePaths{:}];
allCallIDs = [allCallIDs{:}];
allStartTimes

% create segments.txt file with info about segments
outputFileName = 'segments.txt';
outFileID = fopen(fullfile(outputDir, outputFileName), 'w');
numSegs = length(allStartTimes);
for i = 1:numSegs
    callID = allCallIDs{i};
    segStart = allStartTimes(i);
    segEnd = allStartTimes(i);
    if writeAudio
        segFormat = '%s %s %s %s\n';
        segFilePath = allSegFilePaths{i};
        fprintf(outFileID, segFormat, callID, segStart, segEnd, segFilePath);
    else
        segFormat = '%s %s %s\n';
        fprintf(outFileID, segFormat, callID, segStart, segEnd);
    end
end
fclose(outFileID);
    
%------------- END OF CODE --------------

function [segStartTimes, segEndTimes, segFilePaths] = segmentAudioFile(audioFilePath, outputDir, writeAudio, errorFileID)
% SEGMENTAUDIOFILE - Segment single audio file into regions of continuous speech using the ComboSAD algorithm.
% Helper function for segmentAudioFiles
%
% Syntax: [segStartTimes, segEndTimes, segFilePaths] = segmentAudioFile(audio, outputDir, writeAudio, errorFileID)
%
% Inputs:
%    audioFilePath - Path to audio file to segment.
%    outputDir (string) - Path to directory to write segment audio to (ignored if writeAudio is false).
%    writeAudio (bool) - If true, write audio for each segment to a wav file.
%    errorFileID (int) - ID of text file for logging calls where segmentation fails.
%
% Outputs:
%    segStartTimes (vector of scalars) - Vector of start times for each segment.
%    segEndTimes (vector of scalaras) - Vector of end times for each segment.
%    segFilePaths (cell array of strings) - Each string is path to wav file created for single segment.
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
    [~,callID,~] = fileparts(audioFilePath);
    fprintf(errorFileID, '%s %s %s\n', callID, ME.message, audioFilePath);
    segStartTimes = [];
    segEndTimes = [];
    segFilePaths = {};
    return;
end;
    
segStartTimes = Segments.Start / Fs;
segEndTimes = Segments.Stop / Fs;
segFilePaths = {};

% if writeAudio, write segment audio to files
if writeAudio
    outFileFormat = '%s_%s_%s.wav';
    [~,callID,~] = fileparts(audioFilePath);
    [splitSignal] = splitSignalBySegments(audio, Segments);
    sigsize = size(splitSignal);
    numsegs = sigsize(1);
    for i = 1:numsegs
        segStartStr = int2str(round(segStartTimes(i) * 100));
        segEndStr = int2str(round(segEndTimes(i) * 100));
        outFileName = sprintf(outFileFormat, callID, segStartStr, segEndStr);
        outFilePath = fullfile(outputDir, outFileName);
        audiowrite(outFilePath, splitSignal{i}, Fs);
        segFilePaths{i} = outFilePath;
    end
end

%------------- END OF CODE --------------
