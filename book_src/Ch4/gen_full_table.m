%% set parameter for table
clear;
clc;
gf_M = 8;
gf_2M = 2^gf_M;
gf_2M_mask=2^(gf_M+1)-1; %用于保证数据在GF(2^n)域内
gtable_M = 45;%α^8=α^5+α^3+α^2+1，多项式化简关键，依赖于本原多项式
gtable_M = 29;%α^8=α^4+α^3+α^2+1=2^4+2^3+2^2+1=29，根据本原多项式化简

rev_gtable=zeros(1,gf_2M);
gtable=zeros(1,gf_2M);

gtable(gf_M) = gtable_M;
rev_gtable(gtable_M) = gf_M;
gtable(gf_2M) = 0;
rev_gtable(1) = gf_2M-1; % 下标需要从0开始

%% gen table use primegenerator
shift = 1;
for i = 1: gf_M
    gtable(i) = shift;
    rev_gtable(gtable(i)+1) = i-1;
    shift=bitshift(shift,1);
end
shift = 2^(gf_M-1);
for i = gf_M + 1: gf_2M-1
    if(gtable(i - 1) >= shift)
        temp=bitshift(bitxor(gtable(i - 1),shift),1);%左移，并去除最高位
        gtable(i) =bitxor(gtable_M,temp);%本原多项式化简
    else
        gtable(i) = bitshift(gtable(i - 1),1);
    end
    gtable(i)=bitand(gtable(i),gf_2M_mask);
    rev_gtable(gtable(i)+1) = i-1; %下标从0开始，所以反查表时需要进行修订
end
%% get inverse table
inverse_table=zeros(1,gf_2M); 
inverse_table(1)=0;
for i=1:gf_2M-1 %0没有逆元，所以从1开始  
    k = rev_gtable(i+1);  
    inv_k = gf_2M -1 - k;  
    inv_k = mod(inv_k,gf_2M-1); %= 255; inverse_table的取值范围为 [0, 254]  
    inverse_table(i+1) = gtable(inv_k+1);
end
%% answer
alphaTo= ...
    [  1,   2,   4,   8,  16,  32,  64, 128,  45,  90, 180,  69, 138,  57, 114, 228,...
     229, 231, 227, 235, 251, 219, 155,  27,  54, 108, 216, 157,  23,  46,  92, 184,...
      93, 186,  89, 178,  73, 146,   9,  18,  36,  72, 144,  13,  26,  52, 104, 208,...
     141,  55, 110, 220, 149,   7,  14,  28,  56, 112, 224, 237, 247, 195, 171, 123,...
     246, 193, 175, 115, 230, 225, 239, 243, 203, 187,  91, 182,  65, 130,  41,  82,...
     164, 101, 202, 185,  95, 190,  81, 162, 105, 210, 137,  63, 126, 252, 213, 135,...
      35,  70, 140,  53, 106, 212, 133,  39,  78, 156,  21,  42,  84, 168, 125, 250,...
     217, 159,  19,  38,  76, 152,  29,  58, 116, 232, 253, 215, 131,  43,  86, 172,...
     117, 234, 249, 223, 147,  11,  22,  44,  88, 176,  77, 154,  25,  50, 100, 200,...
     189,  87, 174, 113, 226, 233, 255, 211, 139,  59, 118, 236, 245, 199, 163, 107,...
     214, 129,  47,  94, 188,  85, 170, 121, 242, 201, 191,  83, 166,  97, 194, 169,...
     127, 254, 209, 143,  51, 102, 204, 181,  71, 142,  49,  98, 196, 165, 103, 206,...
     177,  79, 158,  17,  34,  68, 136,  61, 122, 244, 197, 167,  99, 198, 161, 111,...
     222, 145,  15,  30,  60, 120, 240, 205, 183,  67, 134,  33,  66, 132,  37,  74,...
     148,   5,  10,  20,  40,  80, 160, 109, 218, 153,  31,  62, 124, 248, 221, 151,...
       3,   6,  12,  24,  48,  96, 192, 173, 119, 238, 241, 207, 179,  75, 150,   0 ];
 
expOf= ...
   [ 255,   0,   1, 240,   2, 225, 241,  53,   3,  38, 226, 133, 242,  43,  54, 210,...
       4, 195,  39, 114, 227, 106, 134,  28, 243, 140,  44,  23,  55, 118, 211, 234,...
       5, 219, 196,  96,  40, 222, 115, 103, 228,  78, 107, 125, 135,   8,  29, 162,...
     244, 186, 141, 180,  45,  99,  24,  49,  56,  13, 119, 153, 212, 199, 235,  91,...
       6,  76, 220, 217, 197,  11,  97, 184,  41,  36, 223, 253, 116, 138, 104, 193,...
     229,  86,  79, 171, 108, 165, 126, 145, 136,  34,   9,  74,  30,  32, 163,  84,...
     245, 173, 187, 204, 142,  81, 181, 190,  46,  88, 100, 159,  25, 231,  50, 207,...
      57, 147,  14,  67, 120, 128, 154, 248, 213, 167, 200,  63, 236, 110,  92, 176,...
       7, 161,  77, 124, 221, 102, 218,  95, 198,  90,  12, 152,  98,  48, 185, 179,...
      42, 209,  37, 132, 224,  52, 254, 239, 117, 233, 139,  22, 105,  27, 194, 113,...
     230, 206,  87, 158,  80, 189, 172, 203, 109, 175, 166,  62, 127, 247, 146,  66,...
     137, 192,  35, 252,  10, 183,  75, 216,  31,  83,  33,  73, 164, 144,  85, 170,...
     246,  65, 174,  61, 188, 202, 205, 157, 143, 169,  82,  72, 182, 215, 191, 251,...
      47, 178,  89, 151, 101,  94, 160, 123,  26, 112, 232,  21,  51, 238, 208, 131,...
      58,  69, 148,  18,  15,  16,  68,  17, 121, 149, 129,  19, 155,  59, 249,  70,...
     214, 250, 168,  71, 201, 156,  64,  60, 237, 130, 111,  20,  93, 122, 177, 150 ];
	 
 table_err1=(gtable-alphaTo)';
 table_err2=(rev_gtable-expOf)';
 
 %% verification mult
 %% mult;
m=99;
n=169;
err_mult=zeros(gf_2M);
err_div=zeros(gf_2M);
for m=1:gf_2M-1
    for n=3:30 %1:gf_2M-1
        x=rev_gtable(m+1);
        y=rev_gtable(n+1);
        inv_x_y=mod(x+y,gf_2M-1);
        mult_mn=gtable(inv_x_y+1);
        
        inv_n=inverse_table(n+1);
        z=rev_gtable(inv_n+1);
        total_n=z+y;
        inv_x_z=mod(x+z,gf_2M-1);
        div_mn=gtable(inv_x_z+1);
        
        gf_m=gf(m,8);
        gf_n=gf(n,8);
        gf_mn=gf_m*gf_n;
        gf_m_div_n=gf_m/gf_n;
        mult_mn1=gf2dec(gf_mn);
        div_mn1=gf2dec(gf_m_div_n);
        err_mult(m,n)=mult_mn-mult_mn1;
        err_div(m,n)=div_mn-div_mn1;
    end
end
% bit_mn=gftuple(m,8);	%计算GF域中对应的二进制数，注意是八位二进制数
% dec_nb=bi2de(bit_mn);	%二进制转十进制

