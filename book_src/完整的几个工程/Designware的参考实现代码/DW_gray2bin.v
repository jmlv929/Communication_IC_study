
//-------------------------------------------------------------------------------------------------
module DW_gray2bin ( g, b)/* synthesis syn_builtin_du = "weak" */;
parameter width = 8;
input [width-1:0] g;
output [width-1:0] b;

wire [width - 1:0] b = (width == 1) ? g : gray2bin(g);

	// Function to convert gray code to binary
	function  [width - 1:0] gray2bin;
	input [width - 1:0] gray;
	
	integer             i;
	reg   [width - 1:0] tmp;
	
	begin    
		tmp = gray;
	    for (i = 1; i <= width; i = i + 1) 
		begin      
			tmp = tmp ^ (gray >> i);
		end    
		gray2bin = tmp;
	end
	endfunction
 endmodule
