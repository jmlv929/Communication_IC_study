 module add_share (
   input a, b, x, y, sel, en, clk,
   output reg out1, out2
 );
   wire tmp1, tmp2;
   assign tmp1 = a * b;  // tmp1需要一个乘法器
   assign tmp2 = x * y;  // tmp2需要一个乘法器
 
   always@(posedge clk)
     if (en) begin
       out1 <= sel ? tmp1: tmp2; //tmp1与tmp2不同时输出有效
     end else begin
       out2 <= sel ? tmp1: tmp2; //tmp1与tmp2不同时输出有效
     end
 endmodule
