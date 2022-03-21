`timescale 1ns/1ps
/**********************************************************************
*** Filename: rx_round.v
*** Author  : bigdot
*** Date    : 2015-11-1
*** Function:
*** Area    :
**********************************************************************/

module rx_round#(
parameter IN_WIDTH = 8, 
parameter OUT_WIDTH = 5,
parameter UP_CUT_WIDTH =1
)(
input  signed[IN_WIDTH-1:0]  DATA_IN,
output signed[OUT_WIDTH-1:0] DATA_OUT
);
localparam OUT_WIDTH_1 = OUT_WIDTH - 1;//7
localparam TEMP_WIDTH2 = OUT_WIDTH+UP_CUT_WIDTH+1;//8+1+1=10 //
localparam TEMP_WIDTH1 = IN_WIDTH-TEMP_WIDTH2+1;//9-10+1=0

localparam TEMP_WIDTH3 = {UP_CUT_WIDTH+OUT_WIDTH-IN_WIDTH};//7
localparam TEMP_WIDTH4 = {UP_CUT_WIDTH+OUT_WIDTH};//7

wire signed [TEMP_WIDTH2-1:0]temp_data;
wire flag1;
wire flag2;
wire signed [OUT_WIDTH-1:0]  temp_data_bit_more;

wire overflow;
wire signed [TEMP_WIDTH4-1:0]temp_data_big;

generate if(IN_WIDTH>OUT_WIDTH)
begin 
  reg signed [OUT_WIDTH-1:0] DATA_OUT1;
  if(TEMP_WIDTH1==0)
    assign temp_data = {DATA_IN[IN_WIDTH-1],DATA_IN[IN_WIDTH-1:TEMP_WIDTH1]};
  else 
    assign temp_data = {DATA_IN[IN_WIDTH-1],DATA_IN[IN_WIDTH-1:TEMP_WIDTH1]} + DATA_IN[TEMP_WIDTH1-1];

  assign flag1 = ((~|temp_data[TEMP_WIDTH2-1:OUT_WIDTH-1]) || (&temp_data[TEMP_WIDTH2-1:OUT_WIDTH-1])) ? 1'b0 : 1'b1;
  assign flag2 = temp_data[TEMP_WIDTH2-1];
  
  assign  temp_data_bit_more = temp_data[OUT_WIDTH-1:0];
  always @(flag1 or flag2 or temp_data_bit_more)
  begin
    if (flag1)
    begin
      if (flag2)
        DATA_OUT1 = {1'b1,{OUT_WIDTH_1{1'b0}}};
      else
        DATA_OUT1 = {1'b0,{OUT_WIDTH_1{1'b1}}};
    end
    else
      DATA_OUT1 = temp_data_bit_more;
  end
  assign DATA_OUT=DATA_OUT1;
  
end else begin
  assign temp_data_big = {DATA_IN,{{UP_CUT_WIDTH+OUT_WIDTH-IN_WIDTH}{1'b0}}};
  assign temp_data_big2= temp_data[OUT_WIDTH-1:0];  
  if(UP_CUT_WIDTH>0)
    assign overflow=(DATA_IN[IN_WIDTH-1:IN_WIDTH-UP_CUT_WIDTH-1]=={DATA_IN[IN_WIDTH-1],{{UP_CUT_WIDTH}{~DATA_IN[IN_WIDTH-1]} }});
  else 
    assign overflow=0;
  assign DATA_OUT=overflow?{DATA_IN[IN_WIDTH-1],{{OUT_WIDTH-1}{~DATA_IN[IN_WIDTH-1]}}} : temp_data_big2;
end  
  
endgenerate

endmodule
