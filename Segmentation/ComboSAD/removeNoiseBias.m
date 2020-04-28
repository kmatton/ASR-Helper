function [ outSignal ] = removeNoiseBias( signal, windowSize, stepSize )

% Get params for reconstruction
params = struct();
params.stepSize = stepSize;
params.audioLength = numel(signal);

% Pad with first and last value on both ends (windowSize/2 length)
outSignal = signal;
startMed = median(outSignal(1:(windowSize/2)));
stopMed = median(outSignal(end-(windowSize/2)+1:end));
outSignal = [repmat(startMed,windowSize/2,1); outSignal; repmat(stopMed,windowSize/2,1)];

% Calculate number of frames needed
nli=numel(outSignal)-windowSize+stepSize;
nf = max(fix(nli/stepSize),0);   % number of full frames
na=nli-stepSize*nf+(nf==0)*(windowSize-stepSize); % number of samples left over
fx=na>0; % need an extra row
nf=nf+fx;
outSignal = [outSignal; repmat(stopMed,stepSize-na,1)];

% Get percentile signal
frameStart = 1;
prctSignal = NaN(nf,1);
for fOn = 1:nf
    % Get the frame and advance the counter
    segment = outSignal(frameStart:frameStart+windowSize-1);
    frameStart = frameStart + stepSize;
    prctSignal(fOn) = prctile(segment,1);
end

% Remove bias
outSignal = signal-resampleSignalAfterWindowing(prctSignal, params);