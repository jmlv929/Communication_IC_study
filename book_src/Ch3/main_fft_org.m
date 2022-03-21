function data_out=Main_fft(data_in,N,num,shift)
global fft_bit;

if nargin==3
    shift=[0,0];
end
data_first=zeros(1,N);

data_first_temp=zeros(2,N/2);
data_second=zeros(2,N/2);

data_second_temp=zeros(4,N/4);
data_third=zeros(4,N/4);

%first stage
data_first=fft_s(data_in,N);%bit:data_in+1
%first stage dispose
data_first_temp(1,:)=data_first(1:N/2);%bit:data_in+1
data_first_temp(2,1:N/4)=data_first(N/2+1:N/2+N/4);
data_first_temp(2,N/4+1:N/2)=data_first(N/2+N/4+1:N)*(-j);

%second stage
for m=1:1:2
    data_second(m,:)=fft_s(data_first_temp(m,:),N/2);%bit:data_in+2
end
    
%second stage dispose

%  W=exp(-2*pi*j/N);
% data_second_temp(1,:)=data_second(1,1:N/4);
% data_second_temp(2,:)=data_second(1,N/4+1:N/2).*power(W,2*[0:1:(N-1)/4]);
% data_second_temp(3,:)=data_second(2,1:N/4).*power(W,[0:1:(N-1)/4]);
% data_second_temp(4,:)=data_second(2,N/4+1:N/2).*power(W,[0:1:(N-1)/4]+2*[0:1:(N-1)/4]);
% 

%use fixed point multiply!
mul_addr=zeros(4,N/4);
mul_result=zeros(4,N/4);
% switch fft_bit
% case 10 
%     a=4;
%     b=0;
%     
% case 11
%     a=2;
%     b=1;
% case 12
%     a=1;
%     b=3;
% end;    
% fft_bit=10;
temp1=mult(8,shift(1));%bit:Getbit
temp2=mult(8,shift(2));

%%%%%%%%%%%%%%%%%$$$$$$$^* + ^$$$$$$$$$$$$$$$$$$$$
%%%%%%%%%%%%%%%%%%%%%%%%( @ )%%%%%%%%%%%%%%%%%%%%%%%
switch num
case 1
   data_second=num2fixpt(data_second/4,sfix(10),1,'nearest','on');
case 2
    data_second=num2fixpt(data_second/4,sfix(10),1,'nearest','on');
case 3
%     data_second=num2fixpt(data_second,'sfix',(12),1,'nearest','on');
 data_second=data_second;
end
    
 

data_second_temp(1,:)=data_second(1,1:N/4)*temp1;%bit: getbit+data_in+2
% mul_addr(1,:)=shift(1)*ones(1,N/4);
% mul_result(1,:)=temp1*ones(1,N/4)*power(2,fft_bit-1);

%data_second_temp(2,:)=data_second(1,N/4+1:N/2).*mult(N,2*[0:1:(N-1)/4])*temp1;
data_second_temp(2,:)=data_second(1,N/4+1:N/2).*mult(N,2*[0:1:(N-1)/4]+2*shift(1)*ones(1,N/4));%bit: getbit+data_in+2

% mul_addr(2,:)=2*[0:1:(N-1)/4]+2*shift(1)*ones(1,N/4);
% mul_result(2,:)=mult(N,2*[0:1:(N-1)/4])*temp1*power(2,fft_bit-1);

% data_mm=data_second(1,N/4+1:N/2).*power(W,2*[0:1:(N-1)/4]);
%data_second_temp(3,:)=data_second(2,1:N/4).*mult(N,[0:1:(N-1)/4])*temp2;
data_second_temp(3,:)=data_second(2,1:N/4).*mult(N,[0:1:(N-1)/4]+2*shift(2)*ones(1,N/4));
% mul_addr(3,:)=[0:1:(N-1)/4]+2*shift(2)*ones(1,N/4);
% mul_result(3,:)=mult(N,[0:1:(N-1)/4])*temp2*power(2,fft_bit-1);

%data_second_temp(4,:)=data_second(2,N/4+1:N/2).*mult(N,[0:1:(N-1)/4]+2*[0:1:(N-1)/4])*temp2;
data_second_temp(4,:)=data_second(2,N/4+1:N/2).*mult(N,[0:1:(N-1)/4]+2*[0:1:(N-1)/4]+2*shift(2)*ones(1,N/4));
% mul_addr(4,:)=[0:1:(N-1)/4]+2*[0:1:(N-1)/4]+2*shift(2)*ones(1,N/4);
% mul_result(4,:)=mult(N,[0:1:(N-1)/4]+2*[0:1:(N-1)/4])*temp2*power(2,fft_bit-1);

data_out=zeros(1,N);

for m=1:4
    data_out((m-1)*N/4+1:m*N/4)=data_second_temp(m,:);
end
