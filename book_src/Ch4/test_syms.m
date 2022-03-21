%% poly syms test
syms a b c d e
syms fx
fx=[ a 0 0; b a 0; c b a];
tx=inv(fx)

fx=[ a 0 0 0; b a 0 0; c b a 0; d c b a];
tx=inv(fx)

fx=[ a 0 0 0 0; b a 0 0 0; c b a 0 0 ; d c b a 0;e d c b a ];
tx=inv(fx)
