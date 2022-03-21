`timescale 1ns/1ps
 // **********************************
 // *** Filename: data_round.v
 // *** Author  : li
 // *** Date    : 2003-06-06
 // *** Function:
 // *** Area    :
 // **********************************

module data_round #(
parameter IN_WIDTH = 8,
parameter OUT_WIDTH = 6,
parameter UP_CUT_WIDTH = 0)(
input [IN_WIDTH-1:0]  DATA_IN,
output reg[OUT_WIDTH-1:0] DATA_OUT
);
localparam OUT_WIDTH_1 = OUT_WIDTH - 1;
localparam TEMP_WIDTH2 = OUT_WIDTH+UP_CUT_WIDTH+1;
localparam TEMP_WIDTH1 = IN_WIDTH-TEMP_WIDTH2+1;

//reg   [OUT_WIDTH-1:0] DATA_OUT;
wire  [TEMP_WIDTH2-1:0]temp_data;
wire                  flag1;
wire                  flag2;

assign temp_data={DATA_IN[IN_WIDTH-1],DATA_IN[IN_WIDTH-1:TEMP_WIDTH1]}+DATA_IN[TEMP_WIDTH1-1];
assign flag1 = ((~|temp_data[TEMP_WIDTH2-1:OUT_WIDTH-1]) 
              || (&temp_data[TEMP_WIDTH2-1:OUT_WIDTH-1]))? 1'b0 : 1'b1;
assign flag2 = temp_data[TEMP_WIDTH2-1];

wire  [OUT_WIDTH-1:0]  temp_data_bit_more;
assign temp_data_bit_more = temp_data[OUT_WIDTH-1:0];

always @(flag1 or flag2 or temp_data_bit_more)
  if (flag1) begin
    if (flag2) 
	  DATA_OUT = {1'b1,{OUT_WIDTH_1{1'b0}}};
    else 
	  DATA_OUT = {1'b0,{OUT_WIDTH_1{1'b1}}};
  end
  else 
    DATA_OUT = temp_data_bit_more;

endmodule
