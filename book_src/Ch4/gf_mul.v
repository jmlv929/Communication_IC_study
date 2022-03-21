module  GfMul #(parameter  m  =  4)(
input   [0:m-1]  a , // 乘法输入a
input   [0:m-1]  b , // 乘法输入b
input   [0:m-1]  p , // 生成多项式
output  [0:m-1]  y   // 乘法结果
);
wire    [0:m-1]  s  [0:m-1] ;
// 将中间结果进行初始化
assign  s[0]  =  {m{a[0]}} & b;
// 对输入的每个bit依次进行迭代
genvar  i ;
generate
begin
  for  ( i  =  1 ;  i  <=  (m-1) ;  i  =  i + 1 )
    begin  :  rows
      assign  s[i]  = ({(m){a[i]}} & b) ^ ({(m){s[i-1][0]}} & p)^({ s[i-1][1:m-1] , 1'b0 });
    end
end
endgenerate
// 将m-1行的结果（累加了m-1次），作为乘法输出
assign  y  =  s[m-1] ;
endmodule
