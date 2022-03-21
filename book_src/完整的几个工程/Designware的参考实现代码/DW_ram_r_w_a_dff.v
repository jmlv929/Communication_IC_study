
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// ABSTRACT:  Dual port (1 write port, 1 read port) DFF based RAM
//            with parameter driven retiming register insertion
//
//              Parameters:     Valid Values
//              ==========      ============
//	 	data_width     	[ 1 to 256 ]
//	 	depth     	[ 2 to 256 ]
//              rst_mode        [ 0 to 1 ]
//              
//              Input Ports     Size    Description
//              ============    ====    ===========
//	        rst_n           1 bit	Active Low asynchronous Reset
//	        cs_n            1 bit	Active Low Chip Select
//	        wr_n            1 bit	Active Low Write Control
//              test_mode       1 bit   Active high test mode enable
//              test_clk        1 bit   Positive edge test mode clock
//              rd_addr         N bits  Read Address
//              wr_addr         N bits  Write Address
//	        data_in         W bits  Input Data (for writes)
//
//              Output Port     Size    Description
//              ============    ====    ===========
//	        data_out	W bits	Output Data (from reads)
//
//                Note: N is defined as addr_width - a parameter which should
//                      be set (by the parent design) to ceil( log2( depth ) )
//
//                      W is defined as the data_width parameter
//
//
//	MODIFIED:
//
////////////////////////////////////////////////////////////////////////////////


  module DW_ram_r_w_a_dff (
	rst_n,
	wr_n,
	cs_n,
	test_mode,
	test_clk,
        rd_addr,
	wr_addr,
	data_in,
	data_out
	);

   parameter data_width = 4;	// RANGE 1 to 256
   parameter depth = 8;		// RANGE 2 to 256
   parameter rst_mode = 1;	// RANGE 0 to 1

   localparam DW_addr_width = ((depth>256)?((depth>4096)?((depth>16384)?((depth>32768)?16:15):((depth>8192)?14:13)):((depth>1024)?((depth>2048)?12:11):((depth>512)?10:9))):((depth>16)?((depth>64)?((depth>128)?8:7):((depth>32)?6:5)):((depth>4)?((depth>8)?4:3):((depth>2)?2:1))));

   input 			rst_n;		// active low reset
   input 			wr_n;		// active low RAM write enable
   input 			cs_n;		// active low RAM select
   input			test_mode;	// 
   input			test_clk;
   input [data_width-1:0]	data_in;	// RAM write data input bus
   input [DW_addr_width-1:0]	wr_addr;	// RAM write address bus
   input [DW_addr_width-1:0]	rd_addr;	// RAM read address bus

   output [data_width-1:0]	data_out;	// RAM read data output bus


   reg [data_width-1:0]		mem [0 : depth-1];

   wire				mem_clk;


  assign mem_clk = (test_mode==1'b1)? test_clk : (cs_n | wr_n);
  
  generate if (rst_mode == 0) begin : BLK_regs
    always @ (posedge mem_clk or negedge rst_n) begin : PROC_mem_array_regs
      integer i;

      if (rst_n == 1'b0) begin
	//synthesis loop_limit 2000
	for (i=0 ; i < depth ; i=i+1)
	  mem[i] <= {data_width{1'b0}};
      end else begin

	if (test_mode == 1'b1) begin
	  //synthesis loop_limit 2000
	  for (i=0 ; i < depth ; i=i+1)
	    mem[i] <= data_in;
	end else
	  mem[wr_addr] <= data_in;
      end
    end
  end else begin
    always @ (posedge mem_clk) begin : PROC_mem_array_regs
      integer i;
      if (test_mode == 1'b1) begin
	//synthesis loop_limit 2000
	for (i=0 ; i < depth ; i=i+1)
	  mem[i] <= data_in;
      end else
	mem[wr_addr] <= data_in;
    end
  end endgenerate

  assign data_out = (rd_addr < depth)? mem[rd_addr] : {data_width{1'b0}};

endmodule
