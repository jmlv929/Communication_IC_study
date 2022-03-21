pilot=pscale(mod(i,127)+1)*pilot_fft([Signal(Index+16*2:2:Index+64*2-1+Preset*2) Signal(Index+Preset*2:2:Index+15*2)]).*conj([Che(6) Che(20) Che(33) Che(47)]);
pilot_angle=angle(pilot);
