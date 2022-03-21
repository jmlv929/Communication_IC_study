function Hd = cic_128
%CIC_128 Returns a multirate filter object.

%
% MATLAB Code
% Generated by MATLAB(R) 7.12 and the DSP System Toolbox 8.0.
%
% Generated on: 03-Jan-2015 06:41:22
%

decf    = 128;  % Decimation Factor
diffd   = 1;    % Differential Delay
numsecs = 6;    % Number of Sections

Hd = mfilt.cicdecim(decf, diffd, numsecs);

% [EOF]
