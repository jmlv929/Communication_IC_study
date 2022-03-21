%generate_gf,生成域中的所有元素。
function [alpha_to,index_of,gx,hx]=gen_gf(n,k,m)
switch m
    case 3
        Pp = [  1  1  0  1 ];
    case 4
        Pp  = [  1  1  0  0  1 ];
    case 5
        Pp  = [  1  0  1  0  0  1 ];
    case 6
        Pp  = [  1  1  0  0  0  0  1 ];
    case 7
        Pp  = [  1  0  0  1  0  0  0  1 ];
    case 8
        Pp  = [  1  0  1  1  1  0  0  0  1 ];
    case 9
        Pp  = [  1  0  0  0  1  0  0  0  0  1 ];
    case 10
        Pp  = [  1  0  0  1  0  0  0  0  0  0  1 ];
    case 11
        Pp  = [  1  0  1  0  0  0  0  0  0  0  0  1 ];
    case 12
        Pp  = [  1  1  0  0  1  0  1  0  0  0  0  0  1 ];
    case 13
        Pp  = [  1  1  0  1  1  0  0  0  0  0  0  0  0  1 ];
    case 14 ,
        Pp  = [  1  1  0  0  0  0  1  0  0  0  1  0  0  0  1 ];
    case 15
        Pp  = [  1  1  0  0  0  0  0  0  0  0  0  0  0  0  0  1 ];
    case 16
        Pp = [ 1  1  0  1  0  0  0  0  0  0  0  0  1  0  0  0  1 ];
    otherwise
        disp('m 值超出范围');
end

alpha_to=zeros(1,2^m);
mask = 1 ;
alpha_to(m+1) = 0 ;
for i=1:m
    alpha_to(i) = mask ;
    if (Pp(i)~=0)
        alpha_to(m+1)=bitxor(alpha_to(m+1),mask);
    end;
    mask =mask*2;
end;
mask=alpha_to(m);
for i=m+2 : n
    if (alpha_to(i-1) >= mask)
        alpha_to(i) =bitxor( alpha_to(m+1) , bitxor(alpha_to(i-1),mask)*2 );
    else
        alpha_to(i) = alpha_to(i-1)*2 ;
    end;
end;
alpha_to(2^m) = 0;           %把元素0放在最后一位。

%%%%%%%%%%%%%%%%%%%%%%%%% index_of

index_of=zeros(1,2^m);

for i=1:2^m-1
    index_of(alpha_to(i))=i-1;       %alpha_to(i)=alpha^(i-1)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%generate_g(x),计算生成多项式的系数                         低地址对应低次项
gx=zeros(1,n-k+1); %生成多项式次数为n-k                 共n-k+1 项
gx(1) = 2 ;
gx(2) = 1 ;
for i=2:n-k
    gx(i+1) = 1 ;
    for j=i:-1:2
        if (gx(j) ~= 0)
            gx(j)=bitxor(gx(j-1),     alpha_to(mod(index_of(gx(j))+i,2^m-1)+1));
        else
            gx(j) = gx(j-1) ;
        end;
    end;
    gx(1)=alpha_to(mod(index_of(gx(1))+i,2^m-1)+1) ;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%generate_h(x), 计算校验多项式系数  低地址对应低次项

hx=zeros(1,k+1); %校验多项式的次数为k 次，
hx(1)=1;
hx(2)=1;
for i=2:k
    hx(i+1) =1;
    for j=i:-1:2
        if (hx(j) ~= 0)
            hx(j)=bitxor(hx(j-1),  alpha_to(mod(index_of(hx(j))+(i+n-k-1),2^m-1)+1));
        else
            hx(j) = hx(j-1) ;
        end;
    end;
    hx(1)=alpha_to(mod(index_of(hx(1))+(i+n-k-1),2^m-1)+1) ;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
index_gx=zeros(1,n);
index_hx=zeros(1,n);

for i=1:n-k+1
    index_gx(i) = index_of(gx(i));
end;

for i=1:k+1
    index_hx(i) = index_of(hx(i));
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

