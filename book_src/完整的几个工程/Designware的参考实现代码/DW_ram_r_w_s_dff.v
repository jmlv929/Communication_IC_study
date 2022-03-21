
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// ABSTRACT:  Dual port (1 write port, 1 read port) DFF based RAM
//            with parameter driven retiming register insertion
//
//              Parameters:     Valid Values
//              ==========      ============
//	 	data_width     	[ 1 to 2048 ]
//	 	depth     	[ 2 to 1024 ]
//              
//              Input Ports     Size    Description
//              ============    ====    ===========
//	        clk             1 bit   Positive-edge Clock
//	        rst_n           1 bit	Active Low asynchronous Reset
//	        wr_n            1 bit	Active Low Write Control
//	        cs_n            1 bit	Active Low Chip Select
//	        data_in         W bits  Input Data (for writes)
//              wr_addr         N bits  Write Address
//              rd_addr         N bits  Read Address
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


  module DW_ram_r_w_s_dff (
	clk,
	rst_n,
	cs_n,
	wr_n,
	data_in,
	wr_addr,
        rd_addr,
	data_out

// synopsys dc_tcl_script_begin
// set ::suppress_errors [concat $::suppress_errors {EQN-10}]
// set save_suppress_dwbb_ram_r_w_s_dff [lminus $::suppress_errors {EQN-10}]
// set ::suppress_errors {VHDL-2023 UID-95 EQN-19 TIM-103}
// set_design_license -dont_show [find reference "*"] {"DesignWare"}  -quiet
// set_model_load 4 [all_outputs]
// set_model_drive 1 [all_inputs]
// set_structure "true"
// set_flatten "false"
// set_local_link_library { "dw_foundation.sldb" }
// set_attribute [current_design] "date" "03.24.10" -type "string" -quiet
// set_attribute [current_design] "DesignWare" "TRUE" -type "boolean" -quiet
// set_attribute [current_design] "vendor" "Synopsys" -type "string" -quiet
// set_attribute [current_design] "library" "dw06" -type "string" -quiet
// set_attribute [current_design] "keyword" "sequencial" -type "string" -quiet
// set_attribute [current_design] "abstract" "Synchronous Write-port, Asynchronous Read-port RAM Flip-flop-based" -type "string" -quiet
// set_attribute [current_design] "designer" "Rick Kelly" -type "string" -quiet 
// set_attribute [current_design] "DesignWare_version" "99156d17" -type "string" -quiet
// set_attribute [current_design] "DesignWare_release" "D-2010.03:G-2012.06-DWBB_201206.1" -type "string" -quiet
// set ::suppress_errors $save_suppress_dwbb_ram_r_w_s_dff
// unset save_suppress_dwbb_ram_r_w_s_dff
// synopsys dc_tcl_script_end
	);

   parameter data_width = 4;	// RANGE 1 to 2048
   parameter depth = 8;		// RANGE 2 to 1024
   parameter rst_mode = 0;	// RANGE 0 to 1

   localparam DW_addr_width = ((depth>256)?((depth>4096)?((depth>16384)?((depth>32768)?16:15):((depth>8192)?14:13)):((depth>1024)?((depth>2048)?12:11):((depth>512)?10:9))):((depth>16)?((depth>64)?((depth>128)?8:7):((depth>32)?6:5)):((depth>4)?((depth>8)?4:3):((depth>2)?2:1))));

   input 			clk;		// clock input
   input 			rst_n;		// active low reset
   input 			cs_n;		// active low RAM select
   input 			wr_n;		// active low RAM write enable
   input [data_width-1:0]	data_in;	// RAM write data input bus
   input [DW_addr_width-1:0]	wr_addr;	// RAM write address bus
   input [DW_addr_width-1:0]	rd_addr;	// RAM read address bus

   output [data_width-1:0]	data_out;	// RAM read data output bus


   reg [data_width-1:0]		mem [0 : depth-1];

  
  generate if (rst_mode == 0) begin : BLK_regs
    always @ (posedge clk or negedge rst_n) begin : PROC_mem_array_regs
      integer i;

      if (rst_n == 1'b0) begin
	//synthesis loop_limit 2000
	for (i=0 ; i < depth ; i=i+1)
	  mem[i] <= {data_width{1'b0}};
      end else begin
	if (((wr_n | cs_n) == 1'b0) && (wr_addr < depth))
	  mem[wr_addr] <= data_in;
      end
    end
  end else begin
    always @ (posedge clk) begin : PROC_mem_array_regs
      integer i;

      if (rst_n == 1'b0) begin
	//synthesis loop_limit 2000
	for (i=0 ; i < depth ; i=i+1)
	  mem[i] <= {data_width{1'b0}};
      end else begin
	if (((wr_n | cs_n) == 1'b0) && (wr_addr < depth))
	  mem[wr_addr] <= data_in;
      end
    end
  end endgenerate

  assign data_out = (rd_addr < depth)? mem[rd_addr] : {data_width{1'b0}};

endmodule
