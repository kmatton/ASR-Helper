function [ comboSAD, params ] = extractComboSAD( audio, Fs, windowSize, stepSize )
%EXTRACTCOMBOSAD - Extract signal representative of speech likelihood
%
% Syntax:  [comboSAD] = extractComboSAD(audio,Fs,windowSize,stepSize)
%
% Inputs:
%    audio (Nx1 column vector) - Audio signal
%    Fs (scalar) - Sample rate of the audio
%    windowSize (scalar) - Size of the processing window [default=0.032*Fs]
%    stepSize (scalar) - Size of the processing steps [default=0.010*Fs]
%
% Outputs:
%    comboSAD (Mx1 column vector) - Segmentation signal
%    params (struct) - Parameters used in extraction (see
%       resampleSignalAfterWindowing)
%
% Examples (All Equivalent): 
%    extractComboSAD( audio, 8000 )
%    extractComboSAD( audio, 8000, 256, 80 )
%
% Other m-files required: enframe (from VOICEBOX toolbox)
% Subfunctions: none
% MAT-files required: none
%
% References:
%    [1] Sadjadi, Seyed Omid, and John HL Hansen. "Unsupervised speech activity 
%        detection using voicing measures and perceptual spectral flux." Signal 
%        Processing Letters, IEEE 20.3 (2013): 197-200.
%
% Author: John Gideon
% University of Michigan, Department of Computer Science and Engineering
% Email: gideonjn@umich.edu
% September 2015; Last revision: 29-September-2015
%
% See also: formSegments

%------------- BEGIN CODE --------------

% Check that window size exists
if ~exist('windowSize','var')
    windowSize = 0.032*Fs;
end

% Check that window size exists
if ~exist('stepSize','var')
    stepSize = 0.010*Fs;
end

% Pack up params
params.audioLength = numel(audio);
params.Fs = Fs;
params.Fss = Fs/stepSize;
params.windowSize = windowSize;
params.stepSize = stepSize;

% Subtract mean and remove sudden spikes
comboSAD = [];
if numel(audio)==0, error('WARNING: Audio is empty'); return; end
audio = audio - mean(audio);
audio = medfilt1(audio,3,2048);

% Pad with first and last value on both ends (windowSize/2 length)
audio = [repmat(audio(1),windowSize/2,1); audio; repmat(audio(end),windowSize/2,1)];

% Get segmentation
minPitchLag = round(0.002*Fs);
maxPitchLag = round(0.016*Fs);
frames = enframe(audio, windowSize, stepSize, 'z');
nFrames = size(frames,1);
if nFrames==0, error('WARNING: No frames'); return; end
nFeatures = 6;
Features = NaN(nFrames, nFeatures);

% Get time and frequency features
hannWindow = hanning(windowSize);
hammWindow = hamming(windowSize);
nFFT = 2048;
freq = (Fs/2)*linspace(0,1,nFFT/2);
mfBank = melfilter(80,freq,@triang);
prevXm = NaN(1,80);
for fOn = 1:nFrames
    x = frames(fOn,:)';
    if all(x==x(1)), continue; end % Deals with constant signal
    x = x.*hannWindow;
    
    % Autocorrelation (A) - Different from paper (Normalize by maximum
    % potential autocorrelation without window)
    rxx = arrayfun(@(z) (x(z:end)'*x(1:end-z+1))./ ...
        sum(max((x(z:end).^2),(x(1:end-z+1).^2))), 1:maxPitchLag).*sum(x.^2);
    rxx_0 = rxx(1);

    % Check for error
    if ~any(rxx(minPitchLag:end) > rxx_0)
        % Harmonicity (A1)
        rxx_max = max(rxx(minPitchLag:end));
        Features(fOn,1) = rxx_max ./ (rxx_0 - rxx_max);

        % Clarity (A2)
        D_func = @(z) sqrt(2*(rxx_0-z));
        D_minmax = minmax(D_func(rxx(minPitchLag:end)));
        Features(fOn,2) = 1 - (D_minmax(1)/D_minmax(2));

        % Prediction Gain (A3)
        a = lpc(x,10);
        est_x = filter([0 -a(2:end)],1,x);
        resErr = sum(abs(x-est_x));
        Features(fOn,3) = log(rxx_0/resErr);
    end    

    % STFT
    X = abs(fft(frames(fOn,:).*hammWindow',nFFT));
    X = X(1:nFFT/2);

    % Periodicity (B1)
    R = 8;
    P = arrayfun(@(w) sum(arrayfun(@(l) log(X(min_ind(abs(freq-(w*l))))), 1:R)), ...
        62.5:62.5:500);
    Features(fOn,4) = max(P);
    
    % Perceptual Spectral Flux (B2)
    Xm = X*mfBank';
    Xm = Xm./sum(Xm.^2); % Energy Normalized
    Features(fOn,5) = -norm(Xm-prevXm,1);    
    prevXm = Xm;
    
    % RMS Energy (Added in addition to paper)
    Features(fOn,6) = rms(x);
end

% Set all skipped frames to minimum
minVec = nanmin(Features);
ind = find(isnan(Features));
[~,fNum] = ind2sub(size(Features), ind);
Features(ind) = minVec(fNum);

% Normalize
meanVec = mean(Features,1);
stdVec = std(Features,[],1);
Features = (Features-repmat(meanVec,nFrames,1))./repmat(stdVec,nFrames,1);

% PCA
[~,comboSAD,~] = pca(Features);
if numel(comboSAD)==0, error('WARNING: PCA failed'); return; end
comboSAD = real(comboSAD(:,1));

%------------- END OF CODE --------------
