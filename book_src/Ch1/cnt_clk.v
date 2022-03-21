// Gmsk BS clock generator core verilog
// Author: Mr Li Qinghua
// Rev.0.1 2009-02-24
//
module clock_div_async #( parameter cfactor= 2)(
  input clk_in,
  input rst_x,
  output clk_out
);
reg clk_loc;
//reg [15:0] cnt;//allowed maximum clock division factor is 65536
reg [7:0] cnt;//allowed maximum clock division factor is 256

assign clk_out = (cfactor==1)? clk_in : clk_loc;
//assign clk_out = ((rst==1) || (cfactor==1))? clk_in : clk_loc;

always@(posedge clk_in or negedge rst_x)
  if(!rst_x)begin
    cnt <= 'd0;
    clk_loc = 1;
  end
  else begin
    cnt <= cnt + 1'b1;
    if(cnt==cfactor/2-1)
      clk_loc = 0;
    else if(cnt==cfactor-1) begin
      cnt <= 'd0;
      clk_loc = 1;
    end
  end

endmodule
