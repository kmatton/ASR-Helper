function [ Segments ] = formContiguousSegments( comboSAD, minSpeech, minSilence, maxContSpeech )

% Check for too short
if numel(comboSAD) < maxContSpeech
    error('WARNING: ComboSAD signal too short');
end

% Smooth with median filter to remove spikes
smSAD = medfilt1(comboSAD,7,2048);

% Remove baseline bias by subtracting the 1st percentile in sliding window
smSAD = removeNoiseBias(smSAD, maxContSpeech, minSpeech);

% Smooth with hanning window to remove small silences between words
hannWindow = hann(round(minSpeech/2));
smSAD = conv(smSAD,hannWindow,'same')./sum(hannWindow);

% Fit with bimodal GMM and get change point
changePt = findBimodalChangePoint(smSAD, 10, 1000);

% Get binary segmentation signal
smSAD = (smSAD>=changePt);

% Convert to segments
smSAD = [smSAD(1); diff(smSAD)];
Segments = struct();
Segments.Start = find(smSAD==1);
Segments.Stop = find(smSAD==-1)-1;
if numel(Segments.Stop) < numel(Segments.Start)
    Segments.Stop(end+1) = numel(smSAD);
end
Segments = struct2table(Segments);

% Remove min silences
silOn = 1;
while silOn < height(Segments)
    if Segments.Start(silOn+1)-Segments.Stop(silOn) < minSilence
        % Merge segments
        Segments.Stop(silOn) = Segments.Stop(silOn+1);
        Segments(silOn+1,:) = [];
    else
        silOn = silOn + 1;
    end
end
    
% Remove min speech
Segments = Segments((Segments.Stop-Segments.Start)>=minSpeech,:);
