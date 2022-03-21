

//--------------------------------------------------------------------------------------------------
//
// Title       : DW_stack
// Design      : DW_stack


//-------------------------------------------------------------------------------------------------
//
// Description : DW_stack is a fully synchronous, single-clock stack. It combines the DW_stackctl 
// stack controller and the DW_ram_r_w_s_dff flip-flop based RAM DesignWare components. The stack 
// provides parameterized word width and depth, and a full complement of flags: full, empty, and 
// error. The reset mode is selected at instantiation as either synchronous or asynchronous, and 
// to include or exclude the RAM array.
//
// The DW_stack is recommended for relatively small configurations. For large stacks,
// consider using the DW_stackctl in conjunction with a compiled, full-custom RAM array.
//
//-------------------------------------------------------------------------------------------------
`timescale 1ns/10ps
module DW_stack (
	clk, 			//Input clock
	rst_n, 		//Reset input, active LOW
	push_req_n, 	//Stack push request, active LOW
	pop_req_n, 		//Stack pop request, active LOW
	data_in, 		//Stack push data
	empty, 		//Stack empty flag, active HIGH
	full, 		//Stack full flag, active HIGH
	error, 		//Stack error output, active HIGH
      data_out          //Stack pop data
	)/* synthesis syn_builtin_du = "weak" */;

parameter width=8;
parameter depth=16;
parameter err_mode=0;
parameter rst_mode=0; 	
		
`define _synp_dep depth
// +* `include "inc_file.inc"
//$Header: //synplicity/map510rc/designware/inc_file.inc#1 $
//-------------------------------------------------------------------------------------------------
//
// Title       : inc_file.inc 
// Design      : Include file for dw_verilog.v 

// Company     : Synplicity Inc.
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



`define _synp_bit_width `C2BITS

//Input/output declaration
input                  clk;
input                  rst_n;
input                  push_req_n;
input                  pop_req_n;
input [width - 1 : 0]  data_in;
output                 empty;
output                 full;
output                 error;
output [width - 1 : 0] data_out;

//Internal signal declaration
wire [`_synp_bit_width - 1 : 0] wr_addr;  
wire [`_synp_bit_width - 1 : 0] rd_addr;  
wire we_n;
reg reset;

//Internal parameter declaration
parameter rst_mode_ctl = ( rst_mode == 0 ||  rst_mode == 2 ) ? 0 : 1;
parameter rst_mode_ram = ( rst_mode == 0 ||  rst_mode == 2 ) ? 0 : 1;

//Stack Control instantiation
DW_stackctl #(depth, err_mode, rst_mode_ctl ) ctl(
.clk(clk),
.rst_n(rst_n),
.push_req_n(push_req_n),
.pop_req_n(pop_req_n),
.we_n(we_n),
.empty(empty),
.full(full),
.error(error),
.wr_addr(wr_addr),
.rd_addr(rd_addr)
);

//RAM instantiation
DW_ram_r_w_s_dff  #( width, depth, rst_mode_ram )ram
(.clk(clk), .rst_n(reset),.cs_n(1'b0), .wr_n(we_n), .rd_addr(rd_addr), .wr_addr(wr_addr),
.data_in(data_in), .data_out(data_out));

//Reset for RAM
always @ ( rst_n )
	if ( rst_mode == 0 || rst_mode == 1 )
			reset = rst_n;
	else 
			reset = 1'b1;
	
`undef _synp_bit_width
`undef _synp_dep
`undef C0
`undef C1
`undef C2
`undef C3
`undef C4
`undef C5
`undef C2BITS

endmodule
