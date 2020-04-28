function [ changePt ] = findBimodalChangePoint( data, totalIter, kmeansMaxIter )

candidates = NaN(totalIter,1);
for it = 1:totalIter
    [~, C] = kmeans(data, 2, 'MaxIter', kmeansMaxIter);
    candidates(it) = mean(C);
end
changePt = median(candidates);
