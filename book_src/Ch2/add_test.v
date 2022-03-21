01  module add_share (
02    input a, b, x, y, sel, en, clk,
03    output reg out1, out2
04  );
05    wire tmp1, tmp2;
06    assign tmp1 = a * b;  // tmp1需要一个乘法器
07    assign tmp2 = x * y;  // tmp2需要一个乘法器
08  
09    always@(posedge clk)
10      if (en) begin
11        out1 <= sel ? tmp1: tmp2; //tmp1与tmp2不同时输出有效
12      end else begin
13        out2 <= sel ? tmp1: tmp2; //tmp1与tmp2不同时输出有效
14      end
15  endmodule
16  