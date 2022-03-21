clear
syms a b c d
A = [a b; c d];
inv(A)

syms Q1 Q0;
b=a^2;
c=a^3;
B=[a^2 a 1; b^2 b 1;c^2 c 1];
inv(B)

syms m2 m1 m0;
b=a^2;
c=a^3;
B=[a^2*m2 a*m1 1*m0; b^2*m2 b*m1 1*m0;c^2*m2 c*m1 1*m0];
inv(B)

syms m2 m1 m0;
b=a^2;
c=a^3;
B=[a^2*m2 a*m1 1*m0; b^2*m2 b*m1 1*m0;c^2*m2 c*m1 1*m0];
inv(B)


syms m2 m1 m0 test_gf;
m=4;
t=4;
x=zeros(t);
gf_x= gf(x,m);
for i=1:t;
    for j=1:t;
        x(i,j)=(j-1)*i;
        gf_x(i,j)=gf(2,m)^x(i,j)
    end
end

alpha=gf(2,m);
gf_reorder=fliplr(gf_x);

inv_x=inv(gf_x)
inv_x_reorder=inv(gf_reorder)

%% matlab for rs encoder
m=3;
n=6;
k=4;
t=n-k;

x=zeros(t);
gf_x= gf(x,m);
alpha=gf(2,m);

for i=1:t;
    for j=1:t;
        x(i,j)=(j-1)*i;
        gf_x(i,j)=alpha^x(i,j)
    end
end
y=fliplr(x);
gf_y=fliplr(gf_x)
inv_x=inv(gf_x)
inv_y=inv(gf_y)
check_matrix=inv_y*gf_y
%% inv_y is correct matrix for Q-1
enc_x=zeros(t,k);
gf_enc_x=gf(enc_x,m);
enc_x(1,:)=n-1:-1:t;
for i=1:t
    enc_x(t,:)=enc_x(1,:).*t;
    gf_enc_x(t,:)=alpha.^enc_x(t,:);
end

Q_index=inv_y'*gf_enc_x







