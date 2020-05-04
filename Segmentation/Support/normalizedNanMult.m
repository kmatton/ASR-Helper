function [ OutMtrx ] = normalizedNanMult( Mtrx1, Mtrx2 )
% Multiplies two matrices and then divides by the number of non-NaN elements

normMtrx = double(~isnan(Mtrx1))'*double(~isnan(Mtrx2));
Mtrx1(isnan(Mtrx1)) = 0;
Mtrx2(isnan(Mtrx2)) = 0;
OutMtrx = (Mtrx1'*Mtrx2)./normMtrx;