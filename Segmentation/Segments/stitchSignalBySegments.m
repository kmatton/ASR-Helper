function [ signal ] = stitchSignalBySegments( signal, Segments )
%STITCHSIGNALBYSEGMENTS - Stitch together segments of a signal
%
% Syntax:  [ signal ] = stitchSignalBySegments( signal, Segments )
%
% Inputs:
%    signal (Mx1 column vector) - Original signal
%    Segments (Px2 table) - Segmentation times of signal
%       Start (scalar) - Start time of segment
%       Stop (scalar) - Stop time of segment
%
% Outputs:
%    signal (Nx1 column vector) - Stitched signal from segments
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

signal = signal(cell2mat(rowfun(@(Start,Stop) Start:Stop, Segments, 'OutputFormat', 'cell')'),:);

%------------- END OF CODE --------------