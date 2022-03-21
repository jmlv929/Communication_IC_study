 module add_share (
   input a, b, x, y, sel, en, clk,
   output reg out1, out2
 );
   wire tmp1, tmp2;
   assign tmp1 = a * b;  // tmp1��Ҫһ���˷���
   assign tmp2 = x * y;  // tmp2��Ҫһ���˷���
 
   always@(posedge clk)
     if (en) begin
       out1 <= sel ? tmp1: tmp2; //tmp1��tmp2��ͬʱ�����Ч
     end else begin
       out2 <= sel ? tmp1: tmp2; //tmp1��tmp2��ͬʱ�����Ч
     end
 endmodule
