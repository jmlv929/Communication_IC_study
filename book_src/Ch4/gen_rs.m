clear

%% matlab for rs encoder
m=5;
n=31;
k=26;
t=n-k;
alpha=gf(2,m);

%% generate verification matrix
x=zeros(t);
gf_x= gf(x,m);

x(1,:)=t-1:-1:0;
gf_x=gf(x,m);

for i=1:t
    x(i,:)=x(1,:).*i;
end
gf_x=power(alpha,x)

inv_x=inv(gf_x)
check_matrix=inv_x*gf_x
%% inv_y is correct matrix for Q-1
enc_x=zeros(t,k);
gf_enc_x=gf(enc_x,m);
enc_x(1,:)=n-1:-1:t;
for i=1:t
    enc_x(i,:)=enc_x(1,:).*i;
end

gf_enc_x=power(alpha,enc_x)
%% get finnal result for matix gen
Q_index=inv_x*gf_enc_x

%% convert to inv_table
global norml_gf_table inv_gf_table
norml_gf_table=zeros(1,2^m);
inv_gf_table=zeros(1,2^m);
i=2^m-1; %not need since default is zero
 norml_gf_table(i+1)=0;
 inv_gf_table(i+1)=-inf;
for i=0:2^m-2
    bb=gftuple(i,m);
    order=bi2de(bb);
    norml_gf_table(i+1)=order;
    inv_gf_table(order)=i;
end

%% check Q_index for alpha power
for i=0:2^m-1
    tt=get_gf_index(i,m);
    fprintf('exp_of(%d)=%d\n',i,tt);
end

for i=0:2^m-1
    tt=get_gf_data(i,m);
    fprintf('gf(%d)=%d\n',i,tt);
end


%% test final result
 xx=[7           7           1           6];
 xx=[2           3           1           3];
 
 for i=1:length(xx)
    dx(i)=get_gf_index(xx(i),m);
 end
 
 %% caculate generate poly
 syms B fx aa;
 fx=1;
 t=4;
 for i=1:t
     fx=fx*(B-aa^t);
 end

expand(fx) 
 
 
