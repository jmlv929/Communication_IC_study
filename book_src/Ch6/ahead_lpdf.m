function x=ahead_lpf(y);
h=[-2 -2 4 4 -8 -8 9 11 -16 -22 37 115 115 37 -22 -16 11 9 -8 -8 4 4 -2 -2]/256;
yy=[ y ];
len=length(y);
for i=12:2:len-12
    y_mup=yy(i-11:i+12).*h;
    x(i-11)=sum(y_mup);
    x(i+1-11)=x(i-11);
end
