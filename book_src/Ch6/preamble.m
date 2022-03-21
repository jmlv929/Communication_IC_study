clear;
clc
%% short initial
s_ind=1:16;
short_i=[ 47   136  14   146  94   146  14   136  47   2    80   13   0    13   80   2   ] ;
short_q=[ 47   2    80   13   0    13   80   2    47   136   14   146   94   146   14   136 ];   
plot(s_ind,short_i,s_ind,short_q);
grid;
%% short export figure
short=[short_i;short_q];
full_s=repmat(short,1,10);
plot(full_s(1,:));
grid;
export_fig si.png -m2

plot(full_s(2,:),'r');
grid;
export_fig sq.png -m2

%% long initial
l_ind=1:64;
long_i = [ 160 -5 41 99 22 61 -118 -39 100 55 1 -140 25 60 -23 122 64 38 -59 -134 84 71 -62 -58 -36 -125 -130 77 -3 -94 94 13 -160 13 94 -94 -3 77 -130 -125 -36 -58 -62 71 84 -134 -59 38 64 122 -23 60 25 -140 1 55 100 -39 -118 61 22 99 41 -5 ];
long_q =[  0 -123 -114  85  29 -90 -57 -109 -27  4 -118 -49 -60 -15 165 -4 -64 101  40  67  95  14  83 -22 -155 -17 -21 -76  55 118 108 100  0 -100 -108 -118 -55  76  21  17 155  22 -83 -14 -95 -67 -40 -101  64  4 -165  15  60  49 118 -4  27 109  57  90 -29 -85 114 123 ];
plot(l_ind,long_i,l_ind,long_q);
grid;
%% long export figure
long=[long_i;long_q];
full_l=[long(:,33:64) long long];
plot(full_l(1,:));
grid;
export_fig li.png -m2

plot(full_l(2,:),'r');
grid;
export_fig lq.png -m2

