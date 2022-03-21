`timescale 1 ns / 1 ps // Unrolled LFSR (n,k,m)
module conv_217 #(parameter m = 2,parameter n = 7)(
	input clk,rst_n,ena,
	input din,		// bit 0 is to be sent first
	output[m-1:0] cout);
	
wire [n-1:0] g[m-1:0]; //should inverse bit for multiply
assign g[0][n-1:0]=7'b110_110_1;//7'b1_011_011;
assign g[1][n-1:0]=7'b100_111_1;//7'b1_111_001;

reg [n-1:0] conv_buf;
genvar i;
generate
	for (i=0; i<m; i=i+1) begin : lp
		assign cout[i] = ^(g[i][n-1:0]&conv_buf[n-1:0]);		
	end
endgenerate
//assign cout[0]=^(g[0][n-1:0]&conv_buf[n-1:0]);
//assign cout[1]=^(g[1][n-1:0]&conv_buf[n-1:0]);

// din buffer with length n
always @(posedge clk or negedge rst_n)
	if (!rst_n)
		conv_buf <= 0;
	else if (ena) 
		conv_buf[n-1:0] <= {conv_buf[n-2:0],din};

endmodule
