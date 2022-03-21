01 module  GfMul #(parameter  m  =  4)(
02   input   [0:m-1]  a , // 乘法输入a
03   input   [0:m-1]  b , // 乘法输入b
04   input   [0:m-1]  p , // 本原多项式化简项，后面有解释
05   output  [0:m-1]  y   // 乘法结果
06 );
07 wire  [0:m-1]  s  [0:m-1] ;
08 assign  s[0]  =  {m{a[0]}} & b; // 将中间结果进行初始化
09 // 对输入的每个bit依次进行迭代
10 genvar  i ;
11 generate
12 begin
13   for  ( i  =  1 ;  i  <=  (m-1) ;  i  =  i + 1 ) begin  :  rows
14     assign  s[i]  = ({(m){a[i]}} & b) ^ ({(m){s[i-1][0]}} & p)^({ s[i-1][1:m-1] , 1'b0 });
15   end
16 end
17 endgenerate
18 
19 assign  y = s[m-1] ; // 将m-1行的结果（累加了m-1次），作为乘法输出
20 endmodule
21