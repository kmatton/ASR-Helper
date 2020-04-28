function [ Segments ] = formSegments( comboSAD, threshold, minSegment, minSilence )
%FORMSEGMENTS - Form segments out of extracted segmentation signal
%
% Syntax:  [Segments] = formSegments(comboSAD,threshold,minSegment,minSilence)
%
% Inputs:
%    comboSAD (Nx1 column vector) - Segmentation signal
%    threshold (scalar) - Value when to create segments
%    minSegment (scalar) - Minimum size segment to be extracted
%    minSilence (scalar) - Minimum size silence allowed
%
% Outputs:
%    Segments (Mx2 table) - Segmentation times from extracted signal
%       Start (scalar) - Start time of segment
%       Stop (scalar) - Stop time of segment
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% Author: John Gideon
% University of Michigan, Department of Computer Science and Engineering
% Email: gideonjn@umich.edu
% October 2015; Last revision: 1-October-2015
%
% See also: extractComboSAD

%------------- BEGIN CODE --------------

% Initialize empty segments and quit if no signal
Segments = table([], [], 'VariableNames', {'Start', 'Stop'});
if numel(comboSAD)==0, return; end

% Smooth signal and normalize by 5th percentile and std.
hannWindow = hann(minSegment);
smSAD = conv(comboSAD,hannWindow,'same')./sum(hannWindow);
smSAD = (smSAD-prctile(smSAD,5))./std(smSAD);

% Build segments from ComboSAD
winSAD = zeros(numel(comboSAD)+ceil(minSegment/2),1);
for i = 1:numel(smSAD)
    if smSAD(i) > threshold
        updateInd = max([1 floor(i-(minSegment/2))]):ceil(i+(minSegment/2));
        winSAD(updateInd) = 1;
    end
end

% Convert to segment structure left to right
segStruct = struct('Start',[],'Stop',[]);
prevVal = 0;
for i = 1:numel(winSAD)
    if prevVal~=winSAD(i) 
        if prevVal==0
            segStruct.Start = [segStruct.Start; i];
        else
            segStruct.Stop = [segStruct.Stop; i-1];
        end
    end
    prevVal = winSAD(i);
end
if numel(segStruct.Start) ~= numel(segStruct.Stop)
    segStruct.Stop(end+1,1) = numel(winSAD);
end

% Remove silences < minSilence
silSmall = 1;
while numel(silSmall)>0
    silSmall = find(segStruct.Start(2:end)-segStruct.Stop(1:end-1)<minSilence,1);
    if numel(silSmall)>0
        segStruct.Stop(silSmall) = segStruct.Stop(silSmall+1);
        segStruct.Start(silSmall+1) = [];
        segStruct.Stop(silSmall+1) = [];
    end
end

% Convert structure to table
Segments = struct2table(segStruct);

%------------- END OF CODE --------------
