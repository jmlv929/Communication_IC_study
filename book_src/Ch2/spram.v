// Gmsk BS synchronize core verilog
// Author: Mr Li Qinghua
// DDC_GMSK Rev.0.1 2009-02-24
// module simple_dual_port_ram_single_clock

// Usage:
//
// spram
// #(
//    .ADDR_WIDTH(12)  // use 8K byte to implement!
//   ,.DATA_WIDTH(16)
//  )
//  U_RAM
// (
// 	 .clk  (CLK24 ) 
// 	,.data (MEMDOUT) 
// 	,.addr (MEMADDR) 
// 	,.we   (!MEMWRn && !MEMCSn) 
// 	,.q    (MEMDIN) 
// );


module spram 
#(parameter ADDR_WIDTH=6 ,DATA_WIDTH=8)
(
	input [(DATA_WIDTH-1):0] data,
	input [(ADDR_WIDTH-1):0] addr,
	input we, clk,
	output [(DATA_WIDTH-1):0] q
);

	// Declare the RAM variable
	reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];

	// Variable to hold the registered read address
	reg [ADDR_WIDTH-1:0] addr_reg;

	always @ (posedge clk)
	begin
		// Write
		if (we)
			ram[addr] <= data;

		addr_reg <= addr;
	end

	// Continuous assignment implies read returns NEW data.
	// This is the natural behavior of the TriMatrix memory
	// blocks in Single Port mode.  
	assign q = ram[addr_reg];
	
	`ifdef BLANK_RAM
	integer i;
	initial
	begin
		for(i=0;i<2**ADDR_WIDTH;i=i+1)
			ram[i]=0;
	end
	`endif

endmodule
