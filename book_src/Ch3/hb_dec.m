Fpass = 0.048828125;        % Passband Frequency
Dpass = 5.7564627261e-005;  % Passband Ripple

% Calculate the coefficients using the FIRPM function.
b  = firhalfband('minorder', Fpass, Dpass);
Hd = dfilt.dffir(b); 

Fp=0.4;Fs=0.6;ds=0.01;
[M,Wc,beta,ftype] = kaiserord([Fp Fs],[1 0],[ds ds]);
n=mod(M+1,4);M=M+3-n;
k=0:M;
h =0.5*sinc(0.5*(k-0.5*M)).*kaiser(M+1,beta)';
w=linspace(0,pi,512);
H=20*log10(abs(freqz(h,[1],w)));
plot(w/pi,H);grid;
