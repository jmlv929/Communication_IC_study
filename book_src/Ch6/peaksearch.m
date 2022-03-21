switch Stateo
	case 0    PeakPe =  Peak;
	case 1    PeakPe =  Peak * (-j);
	case 2    PeakPe = - Peak;
	case 3    PeakPe =  Peak * (j);
end

diff = mod(Stateo-Statei, 4);
Bibit(1) = floor(diff/2); %diff的MSB
Bibit(2) = xor(mod(diff,2), Bibit(1)); 

if real(Peak)<imag(Peak)  %判断d0
	d0=1;
else
	d0=0;
end
if real(Peak)+imag(Peak)<0  %判断Stateo的MSB d1
	d1=1;
else
	d1=0;
end
d0_1 = xor(d0, d1); %计算Stateo的LSB d0_1

%----确定符号位
c1=sign(divisor);
c2=sign(dividend);
c0=c1*c2;
%====================
dividend=abs(dividend);
divisor=abs(divisor);
%将除数的动态范围设定到0.5~1(不包括1)
while divisor>=1
    divisor=divisor/2;
    dividend=dividend/2;
end
while divisor<0.5
    divisor=divisor*2;
    dividend=dividend*2;
end
 
divisor=num2fixpt(divisor,ufix(8),2^(-8),'nearest','on');
addr=(divisor-0.5)*2×128;
divisor_inv1=invers(addr/128);
divisor_inv=2-addr-divisor_inv1;
result=dividend*divisor_inv*c0;

