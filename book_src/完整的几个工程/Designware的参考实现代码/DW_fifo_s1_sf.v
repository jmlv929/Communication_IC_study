						       
						      
//--------------------------------------------------------------------------------------------------
//
// Title       : DW_fifo_s1_sf
// Design      : DW_fifo_s1_sf


//-------------------------------------------------------------------------------------------------
//
// Description : DW_fifo_s1_sf is a fully synchronous, single-clocked FIFO. It combines the
// DW_fifoctl_s1_df FIFO controller and the DW_ram_r_w_s_dff flip-flop-based RAM DesignWare 
// components.
// The FIFO provides parameterized width and depth, and a full complement of flags: full,
// almost full, half full, almost empty, empty, and error.
// Reset can be selected at instantiation to be either synchronous or asynchronous, and can
// either include or exclude the RAM array.
// The DW_fifo_s1_sf is recommended for relatively small configurations. For large FIFOs,
//  consider using the DW_fifoctl_s1_sf in conjunction with a compiled, full-custom RAM array.
//
//-------------------------------------------------------------------------------------------------

module DW_fifo_s1_sf(clk,rst_n,push_req_n,pop_req_n,diag_n,data_in,empty,almost_empty,half_full,
	almost_full,full,error,data_out)/* synthesis syn_builtin_du = "weak" */;

parameter width = 8;
parameter depth = 4;
parameter ae_level = 1;
parameter af_level = 1;
parameter err_mode = 0;
parameter rst_mode = 0; 

input push_req_n;
input pop_req_n;
input diag_n;
input clk;
input rst_n;
input [width-1:0]data_in;

output full;
output almost_full;
output half_full;
output almost_empty;
output empty;
output error;
output [width-1:0]data_out;
reg  reset;

parameter rst_mode_ctl = ( rst_mode == 0 ||  rst_mode == 2 ) ? 0 : 1;
parameter rst_mode_ram = ( rst_mode == 0 ||  rst_mode == 2 ) ? 0 : 1;

	`define _synp_dep  depth                                                                     
    // +* `include "inc_file.inc"
//$Header: ///map510rc/designware/inc_file.inc#1 $
//-------------------------------------------------------------------------------------------------
//
// Title       : inc_file.inc 
// Design      : Include file for dw_verilog.v 

// Company     :  Inc.
// Date        : Aug 25, 2008
// Version     : 3.1
//
//-------------------------------------------------------------------------------------------------


	`define C0 0+(`_synp_dep>1)+(`_synp_dep>2)+(`_synp_dep>4)+(`_synp_dep>8)+(`_synp_dep>16)+(`_synp_dep>32)+(`_synp_dep>64)                  
	`define C1 +(`_synp_dep>128)+(`_synp_dep>256)+(`_synp_dep>512)+(`_synp_dep>1028)+(`_synp_dep>2046)+(`_synp_dep>4096)              
	`define C2 +(`_synp_dep>8192)+(`_synp_dep>16384)+(`_synp_dep>32768)+(`_synp_dep>65536)+(`_synp_dep>131072)                
	`define C3 +(`_synp_dep>1<<18)+(`_synp_dep>1<<19)+(`_synp_dep>1<<20)+(`_synp_dep>1<<21)+(`_synp_dep>1<<22)                
	`define C4 +(`_synp_dep>1<<23)+(`_synp_dep>1<<24)+(`_synp_dep>1<<25)+(`_synp_dep>1<<26)+(`_synp_dep>1<<27)                
	`define C5 +(`_synp_dep>1<<28)+(`_synp_dep>1<<29)+(`_synp_dep>1<<30)                           
	`define C2BITS `C0 `C1 `C2 `C3 `C4 `C5                             



 	`define _synp_width `C2BITS                                                          

	wire [(`_synp_width-1):0]            wr_addr;                           
	wire [(`_synp_width-1):0]            rd_addr;                           

	
//Fifo Ctrl instantiation	
DW_fifoctl_s1_sf  #( depth, ae_level, af_level, err_mode, rst_mode_ctl ) fifo_ctl
( .clk(clk), .rst_n(rst_n), .push_req_n(push_req_n), .full(full), 
.half_full(half_full), .almost_full(almost_full), .pop_req_n(pop_req_n), .empty(empty),
.almost_empty(almost_empty), .diag_n(diag_n), .error(error), .wr_addr(wr_addr), .we_n(we_n), 
.rd_addr(rd_addr) );										  

//RAM instantiation
DW_ram_r_w_s_dff  #( width, depth, rst_mode_ram  )ram
(.clk(clk), .rst_n(reset),.cs_n(1'b0), .wr_n(we_n), .rd_addr(rd_addr), .wr_addr(wr_addr),
.data_in(data_in), .data_out(data_out));

//Reset for RAM
always @ ( rst_n )
	if ( rst_mode == 0 || rst_mode == 1)
			reset = rst_n;
	else 
			reset = 1'b1;
	
	
`undef _synp_width
`undef _synp_dep
`undef C0
`undef C1
`undef C2
`undef C3
`undef C4
`undef C5
`undef C2BITS

endmodule
