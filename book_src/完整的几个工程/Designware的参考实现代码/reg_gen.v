
module reg_gen # (
									parameter	width		=		1
								 )
								 (
									 input			clk,
									 input			arst_n,
									 input			srst_n,
									 input			enable,
									 input			[width-1:0]	din,
									 output reg [width-1:0]	dout
								 )/* synthesis syn_builtin_du = "weak" */;
	
	always @ (posedge clk or negedge arst_n)
		begin
			if(~arst_n)
				dout <= 0;
			else
				begin
					if(~srst_n)
						dout <= 0;
					else if(enable)
						dout <= din;
				end
		end
endmodule
