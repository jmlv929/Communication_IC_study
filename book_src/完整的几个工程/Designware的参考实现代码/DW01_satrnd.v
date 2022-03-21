

//--------------------------------------------------------------------------------------------------
//
// Title       : DW01_satrnd
// Design      : Arithmetis Saturation and rounding logic

//-------------------------------------------------------------------------------------------------
//
// Description : DW01_satrnd performs arithmetic, precision-handling rounding and saturation functions
// on its input bus din. The width of the din bus is set with the width parameter. The output bus, 
// dout, is a subset of din. The width of dout is determined by the msb_out and lsb_out parameters 
// such that dout equals din(msb_out:lsb_out). 
//
// Fixes :  Nithin
//					VCS Error Fix - When width = msb_out + 1, part select becomes reversed
//-------------------------------------------------------------------------------------------------
`timescale 1 ns / 10ps 
module DW01_satrnd ( din, tc, sat, rnd, ov, dout )/* synthesis syn_builtin_du = "weak" */;

parameter width = 8;
parameter msb_out = 6;
parameter lsb_out = 2;  

//Input/output declaration
input [width - 1 : 0]          din;
input 						   tc;    
input 						   sat;   
input 						   rnd;   
output						   ov;   

output [msb_out - lsb_out : 0] dout;

//Internal signal declaration
reg [msb_out - lsb_out : 0]   sum;
reg                           carry;
wire [msb_out - lsb_out : 0]   dout;
reg                           ov1;
wire                           ov2;
wire                           carry_in;

//Carry generation logic based on input rnd

always @ ( rnd or din )
	if ( rnd && lsb_out != 0 )
		{carry,sum} = din[msb_out : lsb_out] + din[lsb_out - 1];
	else
		begin 
			if ( msb_out == width - 1 )
				{carry,sum} = {1'b0,din[msb_out : lsb_out]}; 
			else
				{carry,sum} = {din[msb_out + 1],din[msb_out : lsb_out]};   
		end		
	
//Overflow logic
always @( tc or carry or din )
	if ( width - 1 == msb_out )
		ov1 = !tc & carry ;
	else 
		ov1 = !tc & ( carry | din[((width - 1 > msb_out + 1) ? width - 1 : msb_out + 1) : ((width - 1 <= msb_out + 1) ? width - 1 : msb_out + 1) ] > 0 );

//assign carry_in = (rnd & lsb_out != 0) ?  & din[msb_out - 1 : lsb_out - 1] : 1'b0; 
assign carry_in = (lsb_out == 0 ) ? 1'b0 : (rnd ?  & din[msb_out - 1 : lsb_out - 1] : 1'b0); 

assign ov2 = ( width - 1 == msb_out ) ? carry ^ carry_in : ( !rnd && ~(din[width - 1 : msb_out] == 0 || din[width - 1 : msb_out] == {width - msb_out {1'b1}})) || ( rnd && ( din[width - 1 : msb_out] == 0 && (carry ^ sum[msb_out-lsb_out])) || ( |din[width - 1 : msb_out] && din[width - 1 : msb_out] != {width - msb_out {1'b1}})); 
assign ov = ov1 | ( tc & ov2 );

//Saturation logic
assign dout = ov & sat ?  ( tc ? ( din[width - 1] ? {1'b1,{msb_out - lsb_out {1'b0}}} : {1'b0, {msb_out - lsb_out {1'b1}}}) : {msb_out - lsb_out + 1{1'b1}} ) : sum;

endmodule
