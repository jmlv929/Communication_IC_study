module abstract_fx_add#(parameter BIT_W=8,parameter N=64 )(
	input clk,
	input reset,
	input start_fx,
	input [BIT_W-1:0]x_in,
	output fx_finish,	
	output [BIT_W-1:0] fx_out
);
reg [7:0] control_cnt;
always @(posedge clk or negedge reset)
 if(!reset)
 	control_cnt<=0;
 else if(start_fx)
	control_cnt<=0;
 else if(control_cnt<N)
 	control_cnt<=control_cnt+1'b1;

assign fx_finish=(control_cnt==N) ? 1'b1 : 1'b0;

function[BIT_W-1:0] subfx;
  input [BIT_W-1:0] x;
  begin
  	subfx=fx_i(x);
  end
endfunction

reg [2*BIT_W-1:0] sum_acc;
always @(posedge clk or negedge reset)
 if(!reset)
 	sum_acc<=0;
 else if(control_cnt<N)
  sum_acc<=sum_acc+subfx(x_in);

assign fx_out=sum_acc[2*BIT_W-1:BIT_W];

endmodule
