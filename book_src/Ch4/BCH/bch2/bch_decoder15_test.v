`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////
module bch_decoder15_test;

	// Inputs
	reg clk;
	reg [14:0] r;

	// Outputs
	wire [14:0] c;

	// Instantiate the Unit Under Test (UUT)
	bch_decoder15 uut (
		.clk(clk), 
		.r(r), 
		.c(c)
	); 
	
	initial begin 
	  		forever #25 clk=!clk; 
	end 
	
	initial begin
		// Initialize Inputs
		clk = 0;
		r = 0;

		// Wait 100 ns for global reset to finish
		#200; 
      r=15'b0000_1000_0001_000;
		// Add stimulus here

	end
      
endmodule