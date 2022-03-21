
//-------------------------------------------------------------------------------------------------
// Module      : DW01_mux_any
// Author      : Nithin Kumar
// Company     :  Inc. 
// Date        : 13th Sept, 07
// Version     : 
// Description : Universal multiplexer.
//-------------------------------------------------------------------------------------------------
module DW01_mux_any 
									#(
											parameter A_width 	= 512,
																SEL_width = 8,
																MUX_width = 2 													
										)
										(
				            input	[A_width-1:0]					A,
										input	[SEL_width-1:0]				SEL,
										output	reg	[MUX_width-1:0]	MUX
										)/* synthesis syn_builtin_du = "weak" */;

localparam	MAX_inputs = (2**SEL_width);										

integer i;			

//wire [(MAX_inputs*MUX_width)-1:0]	A_int = {{(MAX_inputs*MUX_width){1'b0}},A};
 reg [(MAX_inputs*MUX_width)-1:0]	A_int; // Modified by Nithin (work around for VCS) 

wire [MUX_width-1:0]	mux_d [MAX_inputs-1:0];

// Modified by Nithin (work around for VCS) 
always @ *
	begin
		A_int = 0;
		A_int = A;
	end
// Modified by Nithin (work around for VCS) 


genvar j;
generate
    // synthesis loop_limit 5000  
		for(j=0;j<MAX_inputs;j=j+1)
			begin:u
				assign	mux_d[j] = A_int[((j+1)*MUX_width)-1:(j*MUX_width)];
			end
endgenerate

always @ *
	begin
		MUX = 0;
    // synthesis loop_limit 5000  
		for(i=0;i<MAX_inputs;i=i+1)
			if(i == SEL)
				MUX = mux_d[i];
	end	
endmodule
