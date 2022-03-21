

	//--------------------------------------------------------------------------------------------------
//
// Title       : DW04_shad_reg
// Design      : DW04_shad_reg


//-------------------------------------------------------------------------------------------------
//
// Description : DW04_shad_reg is a parameterized register pair. The first register is a parallel
// load, parallel output system register clocked on the sys_clk pin with an asynchronous reset
// controlled by the reset pin. The register is implemented in multibit (ganged) flip-flop
// cells if available in the target technology. The datain signal drives the DW04_shad_reg
// inputs and the output is sys_out.
// The second register is a shadow register, which, like the system register, is also width bits
// wide and implemented in the same target technology cells. However, the shadow register
// is a parallel load shift register, which captures the output of the system register when
// sampled by shad_clk. This register outputs its contents to shad_out (parallel) and SO(serial).
//
//-------------------------------------------------------------------------------------------------

module DW04_shad_reg ( datain, sys_clk, shad_clk, reset, SI, SE, sys_out, shad_out, SO )/* synthesis syn_builtin_du = "weak" */;

parameter width = 8;
parameter bld_shad_reg = 1;

//Input/output declaration
input [width - 1 : 0]  datain;   
input 				   SI;       
input 				   SE;       
input 				   sys_clk;  
input 				   shad_clk; 
input 				   reset;    
output [width - 1 : 0] sys_out;
output [width - 1 : 0] shad_out;
output                 SO;

//Internal signal declaration
reg [width - 1 : 0]  tmpdatain;
reg [width - 1 : 0]  serial;
wire [width - 1 : 0] tmp_shadin;
reg [width - 1 : 0]  shad_out;
wire [width - 1 : 0] sys_out;
integer	             i;
//Update the output
assign sys_out = tmpdatain;
assign SO = shad_out[width - 1];
//Mux implementation
assign tmp_shadin = SE ? serial : tmpdatain;

//Implementing shift register
always @ ( shad_out or SI )
	begin
		serial[0] = SI;
		// synthesis loop_limit 2000  
		for ( i = 0; i < width - 1; i = i + 1 )
			serial[i+1] = shad_out[i];
	end

//Registering the input data
always @(posedge sys_clk or negedge reset)
	if (!reset)	
		tmpdatain <= 0;
	else
		tmpdatain <= datain;


//Implementing	shadow register	
always @(posedge shad_clk or negedge reset)
	if (!reset)	 
			shad_out <= 0;
	else
		begin
			if ( bld_shad_reg )
					shad_out <= tmp_shadin;
			else
					shad_out <= 0;
		end

endmodule
