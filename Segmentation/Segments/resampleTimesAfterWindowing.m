function [ Segments ] = resampleTimesAfterWindowing( Segments, params )
%RESAMPLETIMESAFTERWINDOWING - Scale segmentation times to original audio
%
% Syntax:  [ Segments ] = resampleTimesAfterWindowing( Segments, params )
%
% Inputs:
%    Segments (Mx2 table) - Segmentation times from extracted signal
%       Start (scalar) - Start time of segment
%       Stop (scalar) - Stop time of segment
%    params (struct) - Parameters used in segmentation extraction
%       audioLength (scalar) - Length of original audio
%       Fs (scalar) - Sample frequency of original audio
%       Fss (scalar) - Sample freqency of segmentation signal
%       windowSize (scalar) - window used for segmentation signal extraction
%       stepSize (scalar) - step size used for segmentation signal extraction
%
% Outputs:
%    Segments (Mx2 table) - Segmentation times scaled to original audio
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
% See also: resampleSignalAfterWindowing

%------------- BEGIN CODE --------------

% Convert
Segments = varfun(@(z) round(z*params.stepSize), Segments);
Segments.Properties.VariableNames = {'Start', 'Stop'};
Segments.Stop = Segments.Stop - 1;

% Sanity Check
Segments.Start = max(Segments.Start, 1);
Segments.Stop = max(Segments.Stop, 1);
Segments.Start = min(Segments.Start, params.audioLength);
Segments.Stop = min(Segments.Stop, params.audioLength);

%------------- END OF CODE --------------