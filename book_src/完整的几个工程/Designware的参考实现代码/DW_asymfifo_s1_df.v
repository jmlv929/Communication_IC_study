
//--------------------------------------------------------------------------------------------------
//
// Title       : DW_asymfifo_s1_df
// Design      : DW_asymfifo_s1_df


//-------------------------------------------------------------------------------------------------
//
// Description : DW_asymfifo_s1_df is a fully synchronous, single-clock FIFO. It combines the
// DW_asymfifoctl_s1_df FIFO controller and the DW_ram_r_w_s_dff flip-flop-based RAM component.
//
//-------------------------------------------------------------------------------------------------

module DW_asymfifo_s1_df (
 	clk, 
	rst_n,
	push_req_n, 
	flush_n,
	pop_req_n,
	diag_n,
	data_in,
	ae_level, 
	af_thresh,
	empty,
	almost_empty, 
	half_full,
	almost_full,
	full,
	ram_full,
	error,
	part_wd,
	data_out	
	)/* synthesis syn_builtin_du = "weak" */;

	
	parameter 	data_in_width	 	= 16;
	parameter 	data_out_width 		= 16;
	parameter 	depth				= 32;
	parameter 	err_mode			= 1;
	parameter 	rst_mode			= 1; 
	parameter 	byte_order 			= 0;  
	parameter width = (data_in_width > data_out_width)? data_in_width : data_out_width; 

	`define _synp_dep depth                                                                     
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

	input push_req_n;
	input pop_req_n;
	input [data_in_width-1 : 0] data_in;
	input flush_n;
	input [`_synp_width-1:0]ae_level;
	input [`_synp_width-1:0]af_thresh;
	input diag_n;
	input clk;
	input rst_n;


	output [data_out_width-1 : 0] data_out;
	output ram_full;
	output part_wd; 
	output full;
	output almost_full;
	output half_full;
	output almost_empty;
	output empty;
	output error;
	reg    reset;

    parameter rst_mode_ctl = ( rst_mode == 0 || rst_mode == 2 ) ? 0 : 1;
    parameter rst_mode_ram = ( rst_mode == 0 || rst_mode == 2 ) ? 0 : 1;

	wire [(`_synp_width - 1) : 0]            wr_addr;                           
	wire [(`_synp_width - 1) : 0]            rd_addr;                           
	wire [((data_in_width > data_out_width)? data_in_width : data_out_width)-1 : 0] rd_data;   
	wire [((data_in_width > data_out_width)? data_in_width : data_out_width)-1 : 0] wr_data;
	wire [data_out_width-1 : 0] data_out;

	DW_asymfifoctl_s1_df #( data_in_width, data_out_width, depth, err_mode, rst_mode_ctl, byte_order) fifo_ctl(
	.clk(clk), 
	.rst_n(rst_n), 
	.push_req_n(push_req_n),
	.flush_n(flush_n),
	.pop_req_n(pop_req_n),
	.diag_n(diag_n),	
	.data_in(data_in), 
	.rd_data(rd_data), 
	.ae_level(ae_level),
	.af_thresh(af_thresh),
	.we_n(we_n), 
	.empty(empty), 
	.almost_empty(almost_empty),
	.half_full(half_full),
	.almost_full(almost_full),
	.full(full), 
	.ram_full(ram_full),
	.error(error),
	.part_wd(part_wd), 
	.wr_data(wr_data),
	.rd_addr(rd_addr),
	.wr_addr(wr_addr), 
	.data_out(data_out)
	); 
	
	//RAM instantiation                                                                        
	DW_ram_r_w_s_dff  #( width, depth, rst_mode_ram  )ram                                      
	(.clk(clk), .rst_n(reset),.cs_n(1'b0), .wr_n(we_n), .rd_addr(rd_addr), .wr_addr(wr_addr),  
	.data_in(wr_data), .data_out(rd_data));                                                   
	
    //Reset for RAM
    always @ ( rst_n )
	   if ( rst_mode == 0 || rst_mode == 1 )
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
