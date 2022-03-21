
`timescale 1ns/1ps
module FIR_5taps(
input   clk, 
input   clk_en, 
input   rst_x, 
input   signed [9:0] filter_in,  //sfix10_En9
output reg signed [19:0] filter_out );//sfix20_En17
// �˲�ϵ�� Constants
parameter signed [9:0] coeff1 = 10'b0001100110; //sfix10_En8
parameter signed [9:0] coeff2 = 10'b0011001101; //sfix10_En8
parameter signed [9:0] coeff3 = 10'b0100000000; //sfix10_En8
parameter signed [9:0] coeff4 = 10'b0011001101; //sfix10_En8
parameter signed [9:0] coeff5 = 10'b0001100110; //sfix10_En8
// internal Signals
reg  signed [9:0] delay_pipeline [0:4] ; // sfix10_En9
wire signed [19:0] sum; // sfix20_En17

//  ���������ݽ��л��棬���������ϵ�����
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
// ϵ��5��4���������,�������2������λ����Ҫȥ��1��
wire [19:0] product5 = delay_pipeline[4] * coeff5;
// ϵ��4��3���������,�������2������λ����Ҫȥ��1��
wire [19:0] product4 = delay_pipeline[3] * coeff4;
// ����ϵ��3����,����ֱ�Ӳ�����λ�����2���������
wire [19:0] product3 = $signed({delay_pipeline[2][9:0], 8'b00000000});
// ϵ��2��1���������,�������2������λ����Ҫȥ��1��
wire [19:0] product2 = delay_pipeline[1] * coeff2;
// ϵ��1��0���������,�������2������λ����Ҫȥ��1��
wire [19:0] product1 = delay_pipeline[0] * coeff1;
// �༶�˷���������ۼ�,��Ҫ������������˴�δ��
assign sum=product1+product2+product3+product4+product5;
// ����������
always @ (posedge clk or negedge rst_x)
    if(!rst_x)
      filter_out <= 0;
    else if (clk_en == 1'b1)
      filter_out <= sum[19:0];
endmodule  // FIR_5taps
