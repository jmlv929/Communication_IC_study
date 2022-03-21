%% iir filter design
syms fm_C
fm_C=1;
syms z  fm1 fm2 fm_num fm_div fm_result fm_hz
N=8
%% set symbols
fm1=fm_C*(z^2+1)*(z^2-1)*(z^2+sqrt(3)*z+1)
fm2=z^6+(1-2^(2-N))
%% get iir result
fm_num=expand(fm1)
fm_div=expand(fm2)
fm_num_fix=sym2poly(fm_num)
fm_div_fix=sym2poly(fm_div)
%% get freqency respond
freqz(fm_num_fix,fm_div_fix)
figure
zplane(fm_num_fix,fm_div_fix)
