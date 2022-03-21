 module add_share1 #(parameter N=8)(
   input [N-1:0] a, b, x, y, 
   input sel, en, clk,
   output reg[N-1:0] out1, out2
 );
   wire [N-1:0] tmp1, tmp2;
   assign tmp1 = a * b;  // tmp1��Ҫһ���˷���
   assign tmp2 = x * y;  // tmp2��Ҫһ���˷���
 
   always@(posedge clk)
     if (en) begin
       out1 <= sel ? tmp1: tmp2; //tmp1��tmp2��ͬʱ�����Ч
     end else begin
       out2 <= sel ? tmp1: tmp2; //tmp1��tmp2��ͬʱ�����Ч
     end
 endmodule
 
  module add_share2 #(parameter N=8)(
   input [N-1:0] a, b, x, y, 
   input sel, en, clk,
   output reg[N-1:0] out1
 );
   wire [N-1:0] tmp1, tmp2;
   assign tmp1 = sel ? a: x; // �˷���A�����
   assign tmp2 = sel ? b: y; // �˷���B�����
 
   always@(posedge clk)
     if (en) begin
       out1 = tmp1 * tmp2;  // �˷������
     end
 endmodule

 module add_share3 #(parameter N=8)(
   input [N-1:0] a, b, x, y, 
   input sel, en, clk,
   output reg[N-1:0] out1
 );
   wire [N-1:0] tmp1, tmp2;
   assign tmp1 = a * b;  // tmp1��Ҫһ���˷���
   assign tmp2 = x * y;  // tmp2��Ҫһ���˷���
 
   always@(posedge clk)
     if (en) begin
       out1 <= sel ? tmp1: tmp2;
     end
 endmodule
