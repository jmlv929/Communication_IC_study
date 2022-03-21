function ParaDecOut = dec_rm(ParaDecIn)

x0 = ones(1,32);
x1 = [0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 ];
x2 = [0 0 1 1 0 0 1 1 0 0 1 1 0 0 1 1 0 0 1 1 0 0 1 1 0 0 1 1 0 0 1 1 ];
x3 = [0 0 0 0 1 1 1 1 0 0 0 0 1 1 1 1 0 0 0 0 1 1 1 1 0 0 0 0 1 1 1 1 ];
x4 = [0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 ];
x5 = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 ];
x6 = x1.*x2;
x7 = x1.*x3;
x8 = x1.*x4;
x9 = x1.*x5;
x10 = x2.*x3;
x11 = x2.*x4;
x12 = x2.*x5;
x13 = x3.*x4;
x14 = x3.*x5;
x15 = x4.*x5;
g = [x0;x1;x2;x3;x4;x5;x6;x7;x8;x9;x10;x11;x12;x13;x14;x15];

x1_bu = ~x1;
x2_bu = ~x2;
x3_bu = ~x3;
x4_bu = ~x4;
x5_bu = ~x5;

x15_pas = sum(rem([x1.*x2.*x3;x1_bu.*x2.*x3;x1.*x2_bu.*x3;x1.*x2.*x3_bu;x1_bu.*x2_bu.*x3;x1_bu.*x2.*x3_bu;x1.*x2_bu.*x3_bu;x1_bu.*x2_bu.*x3_bu]*ParaDecIn',2));
x14_pas = sum(rem([x1.*x2.*x4;x1_bu.*x2.*x4;x1.*x2_bu.*x4;x1.*x2.*x4_bu;x1_bu.*x2_bu.*x4;x1_bu.*x2.*x4_bu;x1.*x2_bu.*x4_bu;x1_bu.*x2_bu.*x4_bu]*ParaDecIn',2));
x13_pas = sum(rem([x1.*x2.*x5;x1_bu.*x2.*x5;x1.*x2_bu.*x5;x1.*x2.*x5_bu;x1_bu.*x2_bu.*x5;x1_bu.*x2.*x5_bu;x1.*x2_bu.*x5_bu;x1_bu.*x2_bu.*x5_bu]*ParaDecIn',2));
x12_pas = sum(rem([x1.*x4.*x3;x1_bu.*x4.*x3;x1.*x4_bu.*x3;x1.*x4.*x3_bu;x1_bu.*x4_bu.*x3;x1_bu.*x4.*x3_bu;x1.*x4_bu.*x3_bu;x1_bu.*x4_bu.*x3_bu]*ParaDecIn',2));
x11_pas = sum(rem([x1.*x5.*x3;x1_bu.*x5.*x3;x1.*x5_bu.*x3;x1.*x5.*x3_bu;x1_bu.*x5_bu.*x3;x1_bu.*x5.*x3_bu;x1.*x5_bu.*x3_bu;x1_bu.*x5_bu.*x3_bu]*ParaDecIn',2));
x10_pas = sum(rem([x1.*x4.*x5;x1_bu.*x4.*x5;x1.*x4_bu.*x5;x1.*x4.*x5_bu;x1_bu.*x4_bu.*x5;x1_bu.*x4.*x5_bu;x1.*x4_bu.*x5_bu;x1_bu.*x4_bu.*x5_bu]*ParaDecIn',2));
x9_pas  = sum(rem([x4.*x2.*x3;x4_bu.*x2.*x3;x4.*x2_bu.*x3;x4.*x2.*x3_bu;x4_bu.*x2_bu.*x3;x4_bu.*x2.*x3_bu;x4.*x2_bu.*x3_bu;x4_bu.*x2_bu.*x3_bu]*ParaDecIn',2));
x8_pas  = sum(rem([x5.*x2.*x3;x5_bu.*x2.*x3;x5.*x2_bu.*x3;x5.*x2.*x3_bu;x5_bu.*x2_bu.*x3;x5_bu.*x2.*x3_bu;x5.*x2_bu.*x3_bu;x5_bu.*x2_bu.*x3_bu]*ParaDecIn',2));
x7_pas  = sum(rem([x4.*x2.*x5;x4_bu.*x2.*x5;x4.*x2_bu.*x5;x4.*x2.*x5_bu;x4_bu.*x2_bu.*x5;x4_bu.*x2.*x5_bu;x4.*x2_bu.*x5_bu;x4_bu.*x2_bu.*x5_bu]*ParaDecIn',2));
x6_pas  = sum(rem([x4.*x5.*x3;x4_bu.*x5.*x3;x4.*x5_bu.*x3;x4.*x5.*x3_bu;x4_bu.*x5_bu.*x3;x4_bu.*x5.*x3_bu;x4.*x5_bu.*x3_bu;x4_bu.*x5_bu.*x3_bu]*ParaDecIn',2));

if x15_pas > 4
	x15_par = 1;
else
	x15_par = 0;
end

if x14_pas > 4
	x14_par = 1;
else
	x14_par = 0;
end

if x13_pas > 4
	x13_par = 1;
else
	x13_par = 0;
end

if x12_pas > 4
	x12_par = 1;
else
	x12_par = 0;
end

if x11_pas > 4
	x11_par = 1;
else
	x11_par = 0;
end

if x10_pas > 4
	x10_par = 1;
else
	x10_par = 0;
end

if x9_pas > 4
	x9_par = 1;
else
	x9_par = 0;
end

if x8_pas > 4
	x8_par = 1;
else
	x8_par = 0;
end

if x7_pas > 4
	x7_par = 1;
else
	x7_par = 0;
end

if x6_pas > 4
	x6_par = 1;
else
	x6_par = 0;
end

m = [x6_par,x7_par,x8_par,x9_par,x10_par,x11_par,x12_par,x13_par,x14_par,x15_par];
s = m*g(7:end,:);
y = s + ParaDecIn;

x5_pas = sum(rem([x1   .*x2   .*x3   .*x4   ;x1_bu.*x2   .*x3   .*x4   ;x1   .*x2_bu.*x3   .*x4   ;x1   .*x2   .*x3_bu.*x4   ;...
                  x1   .*x2   .*x3   .*x4_bu;x1_bu.*x2_bu.*x3   .*x4   ;x1_bu.*x2   .*x3_bu.*x4   ;x1_bu.*x2   .*x3   .*x4_bu;...
                  x1   .*x2_bu.*x3_bu.*x4   ;x1   .*x2_bu.*x3   .*x4_bu;x1   .*x2   .*x3_bu.*x4_bu;x1_bu.*x2_bu.*x3_bu.*x4   ;...
                  x1_bu.*x2_bu.*x3   .*x4_bu;x1_bu.*x2   .*x3_bu.*x4_bu;x1   .*x2_bu.*x3_bu.*x4_bu;x1_bu.*x2_bu.*x3_bu.*x4_bu]*y',2));
x4_pas = sum(rem([x1   .*x2   .*x3   .*x5   ;x1_bu.*x2   .*x3   .*x5   ;x1   .*x2_bu.*x3   .*x5   ;x1   .*x2   .*x3_bu.*x5   ;...
                  x1   .*x2   .*x3   .*x5_bu;x1_bu.*x2_bu.*x3   .*x5   ;x1_bu.*x2   .*x3_bu.*x5   ;x1_bu.*x2   .*x3   .*x5_bu;...
                  x1   .*x2_bu.*x3_bu.*x5   ;x1   .*x2_bu.*x3   .*x5_bu;x1   .*x2   .*x3_bu.*x5_bu;x1_bu.*x2_bu.*x3_bu.*x5   ;...
                  x1_bu.*x2_bu.*x3   .*x5_bu;x1_bu.*x2   .*x3_bu.*x5_bu;x1   .*x2_bu.*x3_bu.*x5_bu;x1_bu.*x2_bu.*x3_bu.*x5_bu]*y',2));
x3_pas = sum(rem([x1   .*x2   .*x5   .*x4   ;x1_bu.*x2   .*x5   .*x4   ;x1   .*x2_bu.*x5   .*x4   ;x1   .*x2   .*x5_bu.*x4   ;...
                  x1   .*x2   .*x5   .*x4_bu;x1_bu.*x2_bu.*x5   .*x4   ;x1_bu.*x2   .*x5_bu.*x4   ;x1_bu.*x2   .*x5   .*x4_bu;...
                  x1   .*x2_bu.*x5_bu.*x4   ;x1   .*x2_bu.*x5   .*x4_bu;x1   .*x2   .*x5_bu.*x4_bu;x1_bu.*x2_bu.*x5_bu.*x4   ;...
                  x1_bu.*x2_bu.*x5   .*x4_bu;x1_bu.*x2   .*x5_bu.*x4_bu;x1   .*x2_bu.*x5_bu.*x4_bu;x1_bu.*x2_bu.*x5_bu.*x4_bu]*y',2));
x2_pas = sum(rem([x1   .*x5   .*x3   .*x4   ;x1_bu.*x5   .*x3   .*x4   ;x1   .*x5_bu.*x3   .*x4   ;x1   .*x5   .*x3_bu.*x4   ;...
                  x1   .*x5   .*x3   .*x4_bu;x1_bu.*x5_bu.*x3   .*x4   ;x1_bu.*x5   .*x3_bu.*x4   ;x1_bu.*x5   .*x3   .*x4_bu;...
                  x1   .*x5_bu.*x3_bu.*x4   ;x1   .*x5_bu.*x3   .*x4_bu;x1   .*x5   .*x3_bu.*x4_bu;x1_bu.*x5_bu.*x3_bu.*x4   ;...
                  x1_bu.*x5_bu.*x3   .*x4_bu;x1_bu.*x5   .*x3_bu.*x4_bu;x1   .*x5_bu.*x3_bu.*x4_bu;x1_bu.*x5_bu.*x3_bu.*x4_bu]*y',2));
x1_pas = sum(rem([x5   .*x2   .*x3   .*x4   ;x5_bu.*x2   .*x3   .*x4   ;x5   .*x2_bu.*x3   .*x4   ;x5   .*x2   .*x3_bu.*x4   ;...
                  x5   .*x2   .*x3   .*x4_bu;x5_bu.*x2_bu.*x3   .*x4   ;x5_bu.*x2   .*x3_bu.*x4   ;x5_bu.*x2   .*x3   .*x4_bu;...
                  x5   .*x2_bu.*x3_bu.*x4   ;x5   .*x2_bu.*x3   .*x4_bu;x5   .*x2   .*x3_bu.*x4_bu;x5_bu.*x2_bu.*x3_bu.*x4   ;...
                  x5_bu.*x2_bu.*x3   .*x4_bu;x5_bu.*x2   .*x3_bu.*x4_bu;x5   .*x2_bu.*x3_bu.*x4_bu;x5_bu.*x2_bu.*x3_bu.*x4_bu]*y',2));

if x5_pas > 8
	x5_par = 1;
else
	x5_par = 0;
end

if x4_pas > 8
	x4_par = 1;
else
	x4_par = 0;
end

if x3_pas > 8
	x3_par = 1;
else
	x3_par = 0;
end

if x2_pas > 8
	x2_par = 1;
else
	x2_par = 0;
end

if x1_pas > 8
	x1_par = 1;
else
	x1_par = 0;
end

x0_pas = sum(rem(x1*x1_par + x2*x2_par + x3*x3_par + x4*x4_par + x5*x5_par + x6*x6_par + x7*x7_par + x8*x8_par + x9*x9_par + x10*x10_par + x11*x11_par + x12*x12_par + x13*x13_par + x14*x14_par + x15*x15_par + ParaDecIn,2));

if x0_pas > 16
	x0_par = 1;
else
	x0_par = 0;
end

ParaDecOut = [x0_par,x1_par,x2_par,x3_par,x4_par,x5_par,x6_par,x7_par,x8_par,x9_par,x10_par,x11_par,x12_par,x13_par,x14_par,x15_par];