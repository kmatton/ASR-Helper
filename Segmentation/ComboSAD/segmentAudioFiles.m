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
% Other m-files required: extractComboSAD, resampleSignalAfterWindowing, 
%    enframe (from VOICEBOX toolbox)
% Subfunctions: segmentAudioFile
% MAT-files required: none

%------------- BEGIN CODE --------------

Enter your executable matlab commands here

%------------- END OF CODE --------------

function [segTimes, segFilePaths] = segmentAudioFile(audioFilePath)
% SEGMENTAUDIOFILE - Segment single audio file into regions of continuous speech using the ComboSAD algorithm.
% Helper function for segmentAudioFiles
%
% Syntax: [segTimes, segFilePaths] = segmentAudioFile(audio, outputDir, writeAudio)
%
% Inputs:
%    audioFilePath - Path to audio file to segment.
%    outputDir (string) - Path to directory to write segment audio to (ignored if writeAudio is false).
%    writeAudio (bool) - If true, write audio for each segment to a wav file.
%
% Outputs:
%    segTimes (list of tuples of scalars) - Each tuple is start and end time for single segment.
%    segFilePaths (list of strings) - Each string is path to wav file created for single segment.
%                     
%
% Other m-files required: extractComboSAD, resampleSignalAfterWindowing, 
%    enframe (from VOICEBOX toolbox)
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
    fprintf('Error: %s\n', ME.message);
    fprintf('file is %s\n', filestr);
    continue;
end;
    
startTimes = Segments.Start / Fs;
endTimes = Segments.Stop / Fs;
