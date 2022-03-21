`timescale 1ns/1ps
/**********************************************************************
*** Filename: rx_squ.v
*** Author  : Shen
*** Date    : 2003-07-01
*** Function:
*** Area    :
**********************************************************************/

module rx_squ
 (//input
  data_i,
  data_q,
  //output
  squ_iq);

parameter          P_SQU = 6;

input [P_SQU-1:0] data_i;
input [P_SQU-1:0] data_q;
output[P_SQU:0] squ_iq;

wire [P_SQU-1:0] i_abs;
wire [P_SQU-1:0] q_abs;
wire [P_SQU-1:0] iq_big;
wire [P_SQU-1:0] iq_small;

assign i_abs = data_i[P_SQU-1] ? ~data_i + 1'b1 : data_i;
assign q_abs = data_q[P_SQU-1] ? ~data_q + 1'b1 : data_q;

assign iq_big = (i_abs >= q_abs) ? i_abs : q_abs;
assign iq_small = (i_abs >= q_abs) ? q_abs : i_abs;

assign squ_iq = iq_big + iq_small[P_SQU-1:2] + iq_small[P_SQU-1:4] + iq_small[P_SQU-1:5];

endmodule
