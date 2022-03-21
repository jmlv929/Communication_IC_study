

//--------------------------------------------------------------------------------------------------
//
// Title       : DW03_shftreg
// Design      : DW03_shftreg

//-------------------------------------------------------------------------------------------------
//
// Description : DW03_shftreg is a shift register of parameterized length. The active LOW load 
// enable, load_n, provides parallel load access and the active LOW shift enable, shift_n, shifts 
// the data. If load_n is set to a constant HIGH value during synthesis, a serial shifter with no 
// parallel access is built. The serial output of the shift register is computed as p_out(length-1).
//
//-------------------------------------------------------------------------------------------------

module DW03_shftreg (clk, s_in, p_in, shift_n, load_n, p_out)/* synthesis syn_builtin_du = "weak" */;
parameter length = 6;

//Input/output declaration
input 				    clk;     
input                   s_in;
input [length - 1 : 0]  p_in;
input 				    shift_n; 
input 				    load_n;  
output [length - 1 : 0] p_out;

//Signal declaration
reg [length - 1 : 0] serial;
reg [length-1 : 0] p_out;
integer	i;

//Combo implementation
always @ ( p_out or s_in )
	begin
		serial[0] = s_in;
    //synthesis loop_limit 2000
		for ( i = 0; i < length - 1; i = i + 1 )
			serial[i+1] = p_out[i];
	end
	
//Shift register implementation	
always @(posedge clk)	
	if (!load_n)
		p_out <= p_in;
	else if (!shift_n )
		p_out <= serial;

endmodule
