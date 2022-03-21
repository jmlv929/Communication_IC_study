`timescale 1ns/1ps
/**********************************************************************
*** Filename: rx_round.v
*** Author  : Shen
*** Date    : 2003-06-06
*** Function:
*** Area    :
**********************************************************************/

module rx_round
 (DATA_IN ,
  DATA_OUT);


parameter IN_WIDTH = 8;
parameter OUT_WIDTH = 6;
parameter UP_CUT_WIDTH = 0;

parameter OUT_WIDTH_1 = OUT_WIDTH - 1;
parameter TEMP_WIDTH2 = OUT_WIDTH+UP_CUT_WIDTH+1;
parameter TEMP_WIDTH1 = IN_WIDTH-TEMP_WIDTH2+1;

input [IN_WIDTH-1:0]  DATA_IN;
output[OUT_WIDTH-1:0] DATA_OUT;

reg   [OUT_WIDTH-1:0] DATA_OUT;

wire  [TEMP_WIDTH2-1:0]temp_data;
wire                  flag1;
wire                  flag2;

assign temp_data = {DATA_IN[IN_WIDTH-1],DATA_IN[IN_WIDTH-1:TEMP_WIDTH1]} + DATA_IN[TEMP_WIDTH1-1];

assign flag1 = ((~|temp_data[TEMP_WIDTH2-1:OUT_WIDTH-1]) || (&temp_data[TEMP_WIDTH2-1:OUT_WIDTH-1])) ? 1'b0 : 1'b1;
assign flag2 = temp_data[TEMP_WIDTH2-1];

wire  [OUT_WIDTH-1:0]  temp_data_bit_more;
assign  temp_data_bit_more = temp_data[OUT_WIDTH-1:0];

always @(flag1 or flag2 or temp_data_bit_more)
begin
  if (flag1)
  begin
    if (flag2)
      DATA_OUT = {1'b1,{OUT_WIDTH_1{1'b0}}};
    else
      DATA_OUT = {1'b0,{OUT_WIDTH_1{1'b1}}};
  end
  else
    DATA_OUT = temp_data_bit_more;
end

endmodule
