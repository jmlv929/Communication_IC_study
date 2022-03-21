02 `timescale 1ns/1ps
03 module FIR_5taps(
04 input   clk, 
05 input   clk_en, 
06 input   rst_x, 
07 input   signed [9:0] filter_in,  //sfix10_En9
08 output reg signed [19:0] filter_out );//sfix20_En17
09 // 滤波系数 Constants
10 parameter signed [9:0] coeff1 = 10'b0001100110; //sfix10_En8
11 parameter signed [9:0] coeff2 = 10'b0011001101; //sfix10_En8
12 parameter signed [9:0] coeff3 = 10'b0100000000; //sfix10_En8
13 parameter signed [9:0] coeff4 = 10'b0011001101; //sfix10_En8
14 parameter signed [9:0] coeff5 = 10'b0001100110; //sfix10_En8
15 // internal Signals
16 reg  signed [9:0] delay_pipeline [0:4] ; // sfix10_En9
17 wire signed [19:0] sum; // sfix20_En17
19 //  将输入数据进行缓存，方便与各级系数相乘
20 always @( posedge clk or negedge rst_x)
21   if(!rst_x) begin
22     delay_pipeline[0] <= 0;
23     delay_pipeline[1] <= 0;
24     delay_pipeline[2] <= 0;
25     delay_pipeline[3] <= 0;
26     delay_pipeline[4] <= 0;
27   end
28   else if (clk_en == 1'b1) begin
29       delay_pipeline[0] <= filter_in;
30       delay_pipeline[1] <= delay_pipeline[0];
31       delay_pipeline[2] <= delay_pipeline[1];
32       delay_pipeline[3] <= delay_pipeline[2];
33       delay_pipeline[4] <= delay_pipeline[3];
34   end
35 // 系数5与4级缓存相乘, 结果包含2个符号位，需要去除1个
37 wire [19:0] product5 = delay_pipeline[4] * coeff5;
38 // 系数4与3级缓存相乘, 结果包含2个符号位，需要去除1个
40 wire [19:0] product4 = delay_pipeline[3] * coeff4;
41 // 由于系数3特殊, 所以直接采用移位完成与2级缓存相乘
43 wire [19:0] product3 = $signed({delay_pipeline[2][9:0], 8'b00000000});
44 // 系数2与1级缓存相乘, 结果包含2个符号位，需要去除1个
46 wire [19:0] product2 = delay_pipeline[1] * coeff2;
47 // 系数1与0级缓存相乘, 结果包含2个符号位，需要去除1个
49 wire [19:0] product1 = delay_pipeline[0] * coeff1;
50 // 多级乘法结果进行累加, 需要做溢出保护，此处未做
52 assign sum=product1+product2+product3+product4+product5;
53 // 输出结果缓存
54 always @ (posedge clk or negedge rst_x)
55  if(!rst_x)
56    filter_out <= 0;
57  else if (clk_en == 1'b1)
58    filter_out <= sum[19:0];
59 endmodule  // FIR_5taps
