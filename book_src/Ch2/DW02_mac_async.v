01 module DW02_mac_async#(parameter A_width = 16,parameter B_width = 16)(
02   input clk, // 时钟
03   input rst_n, // 复位
04   input TC, // unsigned (TC = 0) or signed (TC = 1)
05   input [A_width - 1 : 0]   A, // 乘法输入项A
06   input [B_width - 1 : 0]   B, // 乘法输入项B
07   input [A_width + B_width - 1 : 0] C, // 累加项C
08   output reg[(A_width + B_width)- 1:0] MAC // 乘加结果输出
09 );
10 localparam width = A_width + B_width;
11 //Internal signal declaration
12 reg [width - 1 : 0] temp_a;
13 reg [width - 1 : 0] temp_b;
14 reg [width - 1 : 0] PRODUCT;
15 reg [width - 1 : 0] MAC_comb;
16
17 //Multplying the inputs -- using signed multiplier
18 always @( A or B or TC ) begin
19     temp_a =  TC ? {{width - A_width{A[A_width - 1]}},A}
20                  : {{width - A_width{1'b0}},A};
21     temp_b =  TC ? {{width - B_width{B[B_width - 1]}},B}
22                  : {{width - B_width{1'b0}},B};
23     PRODUCT = temp_a * temp_b;
24     MAC_comb =  temp_a * temp_b + C;
25 end
26
27 always @(posedge clk or negedge rst_n) //异步复位
28   if(!rst_n)
29     MAC <= 0;
30   else
31     MAC <= MAC_comb;
32
33 endmodule