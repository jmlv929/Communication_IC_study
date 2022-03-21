`timescale 1ns/1ps
module FIR_5taps(
  input   clk, 
  input   clk_en, 
  input   rst_x, 
  input   signed [9:0] filter_in,  //sfix10_En9
  output  signed [19:0] filter_out );//sfix20_En17
  // Constants
  parameter signed [9:0] coeff1 = 10'b0001100110; //sfix10_En8
  parameter signed [9:0] coeff2 = 10'b0011001101; //sfix10_En8
  parameter signed [9:0] coeff3 = 10'b0100000000; //sfix10_En8
  parameter signed [9:0] coeff4 = 10'b0011001101; //sfix10_En8
  parameter signed [9:0] coeff5 = 10'b0001100110; //sfix10_En8
  // internal Signals
  reg  signed [9:0] delay_pipeline [0:4] ; // sfix10_En9
  wire signed [18:0] product5; // sfix19_En17
  wire signed [19:0] mul_temp; // sfix20_En17
  wire signed [18:0] product4; // sfix19_En17
  wire signed [19:0] mul_temp_1; // sfix20_En17
  wire signed [18:0] product3; // sfix19_En17
  wire signed [18:0] product2; // sfix19_En17
  wire signed [19:0] mul_temp_2; // sfix20_En17
  wire signed [19:0] product1_cast; // sfix20_En17
  wire signed [18:0] product1; // sfix19_En17
  wire signed [19:0] mul_temp_3; // sfix20_En17
  wire signed [19:0] sum1; // sfix20_En17
  wire signed [19:0] add_signext; // sfix20_En17
  wire signed [19:0] add_signext_1; // sfix20_En17
  wire signed [20:0] add_temp; // sfix21_En17
  wire signed [19:0] sum2; // sfix20_En17
  wire signed [19:0] add_signext_2; // sfix20_En17
  wire signed [19:0] add_signext_3; // sfix20_En17
  wire signed [20:0] add_temp_1; // sfix21_En17
  wire signed [19:0] sum3; // sfix20_En17
  wire signed [19:0] add_signext_4; // sfix20_En17
  wire signed [19:0] add_signext_5; // sfix20_En17
  wire signed [20:0] add_temp_2; // sfix21_En17
  wire signed [19:0] sum4; // sfix20_En17
  wire signed [19:0] add_signext_6; // sfix20_En17
  wire signed [19:0] add_signext_7; // sfix20_En17
  wire signed [20:0] add_temp_3; // sfix21_En17
  reg  signed [19:0] output_register; // sfix20_En17
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
  // 系数5与4级缓存相乘
  assign mul_temp = delay_pipeline[4] * coeff5;
  assign product5 = mul_temp[18:0];
  // 系数4与3级缓存相乘
  assign mul_temp_1 = delay_pipeline[3] * coeff4;
  assign product4 = mul_temp_1[18:0];
  // 由于系数3特殊，所以直接采用移位完成与2级缓存相乘
  assign product3 = $signed({delay_pipeline[2][9:0], 8'b00000000});
  // 系数2与1级缓存相乘
  assign mul_temp_2 = delay_pipeline[1] * coeff2;
  assign product2 = mul_temp_2[18:0];
  // 系数1与0级缓存相乘
  assign mul_temp_3 = delay_pipeline[0] * coeff1;
  assign product1 = mul_temp_3[18:0];
  assign product1_cast = $signed({{1{product1[18]}}, product1});
  // 多级乘法结果进行累加
  assign add_signext = product1_cast;
  assign add_signext_1 = $signed({{1{product2[18]}}, product2});
  assign add_temp = add_signext + add_signext_1;
  assign sum1 = add_temp[19:0];
  assign add_signext_2 = sum1;
  assign add_signext_3 = $signed({{1{product3[18]}}, product3});
  assign add_temp_1 = add_signext_2 + add_signext_3;
  assign sum2 = add_temp_1[19:0];
  assign add_signext_4 = sum2;
  assign add_signext_5 = $signed({{1{product4[18]}}, product4});
  assign add_temp_2 = add_signext_4 + add_signext_5;
  assign sum3 = add_temp_2[19:0];
  assign add_signext_6 = sum3;
  assign add_signext_7 = $signed({{1{product5[18]}}, product5});
  assign add_temp_3 = add_signext_6 + add_signext_7;
  assign sum4 = add_temp_3[19:0];
  // 输出结果缓存
  always @ (posedge clk or negedge rst_x)
      if(!rst_x)
        output_register <= 0;
      else if (clk_en == 1'b1)
        output_register <= sum4;
  assign filter_out = output_register;
endmodule  // FIR_5taps
