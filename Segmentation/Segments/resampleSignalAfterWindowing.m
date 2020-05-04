function [ signal ] = resampleSignalAfterWindowing( signal, params )
%RESAMPLESIGNALAFTERWINDOWING - Scale segmentation signal to original audio
%
% Syntax:  [ signal ] = resampleSignalAfterWindowing( signal, params )
%
% Inputs:
%    signal (Mx1 column vector) - Original segmentation signal
%    params (struct) - Parameters used in segmentation extraction
%       audioLength (scalar) - Length of original audio
%       Fs (scalar) - Sample frequency of original audio
%       Fss (scalar) - Sample freqency of segmentation signal
%       windowSize (scalar) - window used for segmentation signal extraction
%       stepSize (scalar) - step size used for segmentation signal extraction
%
% Outputs:
%    signal (Nx1 column vector) - Segmentation signal scaled to original audio
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
% See also: resampleTimesAfterWindowing

%------------- BEGIN CODE --------------

signal = resample(signal,params.stepSize,1);
signal = signal(1:params.audioLength);

%------------- END OF CODE --------------