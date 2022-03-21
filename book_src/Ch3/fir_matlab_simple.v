
`timescale 1ns/1ps
module FIR_5taps(
input   clk, 
input   clk_en, 
input   rst_x, 
input   signed [9:0] filter_in,  //sfix10_En9
output reg signed [19:0] filter_out );//sfix20_En17
// 滤波系数 Constants
parameter signed [9:0] coeff1 = 10'b0001100110; //sfix10_En8
parameter signed [9:0] coeff2 = 10'b0011001101; //sfix10_En8
parameter signed [9:0] coeff3 = 10'b0100000000; //sfix10_En8
parameter signed [9:0] coeff4 = 10'b0011001101; //sfix10_En8
parameter signed [9:0] coeff5 = 10'b0001100110; //sfix10_En8
// internal Signals
reg  signed [9:0] delay_pipeline [0:4] ; // sfix10_En9
wire signed [19:0] sum; // sfix20_En17

//  将输入数据进行缓存，方便与各级系数相乘
always @( posedge clk or negedge rst_x)
  if(!rst_x) begin
    delay_pipeline[0] <= 0;
    delay_pipeline[1] <= 0;
    delay_pipeline[2] <= 0;
    delay_pipeline[3] <= 0;
    delay_pipeline[4] <= 0;
  end
  else if (clk_en == 1'b1) begin
      delay_pipeline[0] <= filter_in;
      delay_pipeline[1] <= delay_pipeline[0];
      delay_pipeline[2] <= delay_pipeline[1];
      delay_pipeline[3] <= delay_pipeline[2];
      delay_pipeline[4] <= delay_pipeline[3];
  end
// 系数5与4级缓存相乘,结果包含2个符号位，需要去除1个
wire [19:0] product5 = delay_pipeline[4] * coeff5;
// 系数4与3级缓存相乘,结果包含2个符号位，需要去除1个
wire [19:0] product4 = delay_pipeline[3] * coeff4;
// 由于系数3特殊,所以直接采用移位完成与2级缓存相乘
wire [19:0] product3 = $signed({delay_pipeline[2][9:0], 8'b00000000});
// 系数2与1级缓存相乘,结果包含2个符号位，需要去除1个
wire [19:0] product2 = delay_pipeline[1] * coeff2;
// 系数1与0级缓存相乘,结果包含2个符号位，需要去除1个
wire [19:0] product1 = delay_pipeline[0] * coeff1;
// 多级乘法结果进行累加,需要做溢出保护，此处未做
assign sum=product1+product2+product3+product4+product5;
// 输出结果缓存
always @ (posedge clk or negedge rst_x)
    if(!rst_x)
      filter_out <= 0;
    else if (clk_en == 1'b1)
      filter_out <= sum[19:0];
endmodule  // FIR_5taps
