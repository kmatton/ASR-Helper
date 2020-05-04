function [ ind ] = max_ind( vals )
%MAX_IND - Returns the index of the maximum or NaN if it does not exist

[~, ind] = max(vals);
if numel(ind)==0, ind=NaN; end