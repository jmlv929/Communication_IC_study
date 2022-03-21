

//--------------------------------------------------------------------------------------------------
//
// Title       : DW_stackctl
// Design      : DW_stackctl


//
//-------------------------------------------------------------------------------------------------
// Description : DW_stackctl is a stack RAM controller designed to interface with a dual-port 
// synchronous RAM. The stack controller provides address generation, write enable logic, flag 
// logic, and operational error detection logic. Parameterizable features include stack depth 
// (up to 24 address bits or 16,777,216 locations), and type of reset (either asynchronous or 
// synchronous). 
//-------------------------------------------------------------------------------------------------
`timescale 1ns / 10ps
module DW_stackctl( 
	clk, 			//Input clock
	rst_n, 			//Reset input, active LOW
	push_req_n, 	//Stack push request, active LOW
	pop_req_n, 		//Stack pop request, active LOW
	we_n, 			//Write enable for RAM write port, active LOW
	empty, 			//Stack empty flag, active HIGH
	full, 			//Stack full flag, active HIGH
	error, 			//Stack error output, active HIGH
	wr_addr, 		//Address output to write port of RAM
	rd_addr			//Address output to read port of RAM
	)/* synthesis syn_builtin_du = "weak" */;

parameter depth = 16;
parameter err_mode = 0;
parameter rst_mode = 0; 

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
input                               clk;
input                               rst_n;
input                               push_req_n;
input                               pop_req_n;
output                              we_n;
output                              empty;
output                              full;
output                              error;
output [`_synp_bit_width - 1 : 0]   wr_addr;
output [`_synp_bit_width - 1 : 0]   rd_addr;

//Internal signal decalration
reg                            empty_s1;
reg                            full_s1;
reg                            empty_s2;
reg                            full_s2;
reg                            full_c;
reg                            empty_c;
reg                            error_s1;
reg                            error_s2;
wire [`_synp_bit_width - 1 : 0] stack_cnt;
wire [`_synp_bit_width - 1 : 0] stack_top;
reg [`_synp_bit_width - 1 : 0] add_bits;
reg [`_synp_bit_width - 1 : 0] wr_addr_s1;
reg [`_synp_bit_width - 1 : 0] wr_addr_s2;
reg [`_synp_bit_width - 1 : 0] rd_addr_s1;
reg [`_synp_bit_width - 1 : 0] rd_addr_s2;
wire [`_synp_bit_width - 1 : 0] wr_addr_c;
reg [`_synp_bit_width - 1 : 0] rd_addr_c;
wire                           valid_rd;
wire                           valid_wr;
wire [`_synp_bit_width - 1 : 0] wr_stg1;
wire [`_synp_bit_width - 1 : 0] wr_stg2;
wire [`_synp_bit_width - 1 : 0] rd_stg1;
wire [`_synp_bit_width - 1 : 0] rd_stg2;

//Write enable, valid write and valid read control signal generation
assign we_n = push_req_n || full; //Active LOW signal
assign valid_rd = !empty && !pop_req_n && push_req_n;
assign valid_wr = ~we_n; //Active HIGH signal
	
//Addend generation
always @( valid_wr or valid_rd )
	if ( valid_wr )
		add_bits = 1;
	else if ( valid_rd )
		add_bits = {`_synp_bit_width{1'b1}};
	else
		add_bits = 0;

//Stack count generation		  
assign stack_top = valid_wr	? wr_addr : rd_addr;//write- use wr_addr and for read use read_addr
assign stack_cnt = stack_top + add_bits;

//Write_addr generation													  
assign  wr_stg1 = valid_rd ? rd_addr : wr_addr;
assign 	wr_stg2 = empty ? 0 : wr_stg1;
assign  wr_addr_c  = valid_wr && wr_addr != depth-1 ? stack_cnt : wr_stg2; 
		  
//Read_addr generation 
assign rd_stg1 = valid_wr ? wr_addr : rd_addr;
assign rd_stg2 = valid_rd && rd_addr != 0 ? stack_cnt : rd_stg1;

always @( full_c or rd_stg2 )
    if (full_c)
		rd_addr_c = depth - 1;
	else	
		rd_addr_c = rd_stg2;

	always @(posedge clk or negedge rst_n) 
      if (!rst_n) 
		  wr_addr_s1 <= {`_synp_bit_width{1'b0}};           	 
      else 	  
		  wr_addr_s1 <= wr_addr_c;

    always @(posedge clk) 
      if (!rst_n)
		  wr_addr_s2 <= {`_synp_bit_width{1'b0}};           	 
      else 	
		  wr_addr_s2 <= wr_addr_c;
    always @(posedge clk or negedge rst_n ) 
      if (!rst_n) 
		  rd_addr_s1 <= {`_synp_bit_width{1'b0}};           	 
      else 
		  rd_addr_s1 <= rd_addr_c; 	
		  
    always @(posedge clk) 
		if (!rst_n) 
			rd_addr_s2 <= {`_synp_bit_width{1'b0}};           	 
		else 	
			rd_addr_s2 <= rd_addr_c; 
		  

assign wr_addr = (rst_mode == 1) ? wr_addr_s2 : wr_addr_s1;
assign rd_addr = (rst_mode == 1) ? rd_addr_s2 : rd_addr_s1;  

//Empty flag generation
always @( valid_wr or rd_addr or empty ) 
	if ( valid_wr )
		empty_c = 0;
	else if ( rd_addr == 0 )
		empty_c = 1'b1;	
	else
	    empty_c = empty;
	
always @(posedge clk or negedge rst_n)
	if(!rst_n)
		empty_s1 <= 1'b1;
	else
		empty_s1 <= empty_c;

always @(posedge clk)
	if(!rst_n)
		empty_s2 <= 1'b1;
	else
		empty_s2 <= empty_c;
		
assign empty = (rst_mode == 1) ? empty_s2 : empty_s1;		

//Full flag generation
always @ ( full or wr_addr or valid_rd or valid_wr )
	if (valid_rd)
		full_c = 1'b0;
	else if ( wr_addr == depth - 1 && valid_wr )
		full_c = 1'b1;
	else
		full_c = full;

always @(posedge clk or negedge rst_n)
	if(!rst_n)
		full_s1 <= 1'b0;
	else
		full_s1 <= full_c;

always @(posedge clk)
	if(!rst_n)
		full_s2 <= 1'b0;
	else 
		full_s2 <= full_c;

assign full = (rst_mode == 1) ? full_s2 : full_s1;		

//Error flag generation
always @(posedge clk or negedge rst_n)
	if (!rst_n)
	    error_s1 <= 1'b0;
	else
		begin 
			if (err_mode == 0)
				begin
					if ((!push_req_n && full_s1 )||(!pop_req_n && push_req_n && empty_s1))
						error_s1 <= 1'b1;
				end
			else if (err_mode==1)
				begin 
					if  (!push_req_n && !pop_req_n && !full_s1)
						error_s1 <= 1'b0;
					else if ((!push_req_n && full_s1 )||(!pop_req_n && push_req_n && empty_s1))
						error_s1 <= 1'b1;
					else
						error_s1 <= 1'b0;
				end
		end

always @(posedge clk)
	if (!rst_n)
	    error_s2 <= 1'b0;
	else
		begin
			 if (err_mode == 0)
				begin
					if ((!push_req_n && full_s1 )||(!pop_req_n && push_req_n && empty_s1))
						error_s2 <= 1'b1;
				end
			else if (err_mode == 1)
				begin
					if  (!push_req_n && !pop_req_n && !full_s1)
						error_s2 <= 1'b0;
					else if ((!push_req_n && full_s1 )||(!pop_req_n && push_req_n && empty_s1))
						error_s2 <= 1'b1;
					else
						error_s2 <= 1'b0;
				end
		end

assign error = (rst_mode==1) ? error_s2 : error_s1;

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
