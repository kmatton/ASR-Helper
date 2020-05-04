function [ ind ] = min_ind( vals )
%MIN_IND - Returns the index of the minimum or NaN if it does not exist

[~, ind] = min(vals);
if numel(ind)==0, ind=NaN; end