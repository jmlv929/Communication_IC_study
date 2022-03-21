

//--------------------------------------------------------------------------------------------------
//
// Title       : DW_bin2gray 
// Design      : Binary to Gray converter

// 			 
//-------------------------------------------------------------------------------------------------
//
// Description : DW_bin2gray converts binary coded input b to Gray-coded output g.
//
//-------------------------------------------------------------------------------------------------
module DW_bin2gray ( b, g )/* synthesis syn_builtin_du = "weak" */;
parameter width = 8;

input [width - 1:0] b;
output [width - 1:0] g;

wire [width - 1:0] g = (width == 1) ? b : bin2gray(b);

	// Function to convert binary to gray code
	function [width-1:0] bin2gray;
	input [width-1:0] bin;
	begin    
		bin2gray = bin ^ (bin >> 1);
	end
	endfunction	
endmodule
