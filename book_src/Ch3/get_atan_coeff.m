%% Get atan=2^i value
clc
N=12;
theta=zeros(1,N);
for i=1:N
    theta(i)=atan(1/2^i);
    fprintf('%f: tan(%f)=1/(2^%d)=%f\n',theta(i),theta(i),i,1/(2^i));
end
