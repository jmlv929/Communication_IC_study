

//////////// RTL for DW03_reg_s_pl starts here /////
module DW03_reg_s_pl ( d, clk, reset_N, enable, q )/* synthesis syn_builtin_du = "weak" */;

parameter width = 8;
parameter reset_value = 0;

parameter set_value = (width >= 32) ? 0 : reset_value ;

//Input/output declaration
input 				   clk;       
input [width - 1 : 0]  d;
input 				   enable;    
input 				   reset_N;   
output [width - 1 : 0] q;

//Internal signal declartion
reg [width - 1 : 0]    d_in;
reg [width - 1 : 0]    q;

//Implementing combo logic
always @ ( reset_N or enable or q or d )
  if ( ! reset_N )
     d_in = set_value;
  else if ( enable )
     d_in = d;
  else 
     d_in = q;
	 
//Implementing registers	 
always @(posedge clk)
   q <= d_in;

endmodule
