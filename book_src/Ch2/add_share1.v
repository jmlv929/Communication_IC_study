 module add_share1 #(parameter N=8)(
   input [N-1:0] a, b, x, y, 
   input sel, en, clk,
   output reg[N-1:0] out1, out2
 );
   wire [N-1:0] tmp1, tmp2;
   assign tmp1 = a * b;  // tmp1需要一个乘法器
   assign tmp2 = x * y;  // tmp2需要一个乘法器
 
   always@(posedge clk)
     if (en) begin
       out1 <= sel ? tmp1: tmp2; //tmp1与tmp2不同时输出有效
     end else begin
       out2 <= sel ? tmp1: tmp2; //tmp1与tmp2不同时输出有效
     end
 endmodule
 
  module add_share2 #(parameter N=8)(
   input [N-1:0] a, b, x, y, 
   input sel, en, clk,
   output reg[N-1:0] out1
 );
   wire [N-1:0] tmp1, tmp2;
   assign tmp1 = sel ? a: x; // 乘法器A输入端
   assign tmp2 = sel ? b: y; // 乘法器B输入端
 
   always@(posedge clk)
     if (en) begin
       out1 = tmp1 * tmp2;  // 乘法器输出
     end
 endmodule

 module add_share3 #(parameter N=8)(
   input [N-1:0] a, b, x, y, 
   input sel, en, clk,
   output reg[N-1:0] out1
 );
   wire [N-1:0] tmp1, tmp2;
   assign tmp1 = a * b;  // tmp1需要一个乘法器
   assign tmp2 = x * y;  // tmp2需要一个乘法器
 
   always@(posedge clk)
     if (en) begin
       out1 <= sel ? tmp1: tmp2;
     end
 endmodule
