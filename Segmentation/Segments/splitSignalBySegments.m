function [ SplitSignal ] = splitSignalBySegments( signal, Segments )
%SPLITSIGNALBYSEGMENTS - Split signal using segments
%
% Syntax:  [ SplitSignal ] = splitSignalBySegments( signal, Segments )
%
% Inputs:
%    signal (Mx1 column vector) - Original signal
%    Segments (Px2 table) - Segmentation times of signal
%       Start (scalar) - Start time of segment
%       Stop (scalar) - Stop time of segment
%
% Outputs:
%    SplitSignal (Px1 cell) - Each cell contains one segment signal
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
% See also: splitSignalBySegments

%------------- BEGIN CODE --------------

SplitSignal = cellfun(@(sigRange) signal(sigRange,:), ...
    rowfun(@(Start,Stop) Start:Stop, Segments, 'OutputFormat', 'cell'), ...
    'UniformOutput', false);

%------------- END OF CODE --------------