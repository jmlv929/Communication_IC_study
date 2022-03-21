

//--------------------------------------------------------------------------------------------------
//
// Title       : DW_ram_2r_w_a_lat
// Design      : DW_ram_2r_w_a_lat


//
//-------------------------------------------------------------------------------------------------
// Description : DW_ram_2r_w_a_lat implements a parameterized,asynchronous, three-port static RAM.
//-------------------------------------------------------------------------------------------------
module DW_ram_2r_w_a_lat (
                          rst_n,        //Reset, active low
						  cs_n,         //Chip select, active low
						  wr_n,         //Write enable, active low
						  rd1_addr,     //Read address bus
						  rd2_addr,     //Read address bus
						  wr_addr,      //Write address bus
						  data_in,      //Input data bus
						  data_rd1_out, //Output data bus
						  data_rd2_out, //Output data bus
						  )/* synthesis syn_builtin_du = "weak" */;

parameter data_width =  8;
parameter depth = 16;
parameter rst_mode = 1;


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



`define _synp_bit_width `C2BITS

input                           rst_n;
input                           cs_n;
input                           wr_n;
input [`_synp_bit_width-1 : 0]  rd1_addr;
input [`_synp_bit_width-1 : 0]  rd2_addr;
input [`_synp_bit_width-1 : 0]  wr_addr;
input [data_width-1 : 0]        data_in;
output [data_width-1 : 0]       data_rd1_out;
output [data_width-1 : 0]       data_rd2_out;

//Internal signal declaration
reg [data_width-1:0]              data_rd1_out;
reg [data_width-1:0]              data_rd2_out;
wire [data_width-1:0]             out1;
wire [data_width-1:0]             out2;
reg [data_width * depth - 1 : 0]  mem1;
reg [data_width * depth - 1 : 0]  mem2;
reg [data_width * depth - 1 : 0]  data_int;
reg [data_width * depth - 1 : 0]  data_int1;
wire [data_width * depth - 1 : 0] mem;
wire [depth - 1 : 0]              en;

integer i;
integer k;

//Output MUX instantiation
DW01_mux_any #(data_width * depth, `_synp_bit_width, data_width ) out1_mux (.A(mem), .SEL(rd1_addr), .MUX(out1));
DW01_mux_any #(data_width * depth, `_synp_bit_width, data_width ) out2_mux (.A(mem), .SEL(rd2_addr), .MUX(out2));

//address decoder
assign en = 1'b1 << wr_addr;

//Select mem based on rst_mode
assign mem = rst_mode ? mem2 : mem1;

//MEM implementation - asynchronous		
always @( rst_n or data_in or en or cs_n or wr_n or mem1 )
   if ( !rst_n )
	   //synthesis loop_limit 2000
	   for ( i = 0; i < depth; i = i + 1 )
		   begin
			   //synthesis loop_limit 2000
			   for ( k = 0; k < data_width; k = k + 1 )
				   data_int[i * data_width + k] = 1'b0;
		   end
   else
	   //synthesis loop_limit 2000
	   for ( i = 0; i < depth; i = i + 1 )
		   begin
			   if ( en[i] && ~cs_n && ~wr_n )
				   //synthesis loop_limit 2000
				   for ( k = 0; k < data_width; k = k + 1 )
					   data_int[i * data_width + k] = data_in[k];
				else
				   //synthesis loop_limit 2000
				   for ( k = 0; k < data_width; k = k + 1 )
					   data_int[i * data_width + k] = mem1[i * data_width + k];
		   end

		//Latch implementation
		always @( rst_n or wr_n or data_int )
			if ( !wr_n || !rst_n )
				mem1 = data_int;

		//Latch implementation
		always @( wr_n or data_int1 )
			if ( !wr_n )
				mem2 = data_int1;
				
//MEM implementation - synchronous		
always @( en or data_in or cs_n or wr_n or mem2 )
	//synthesis loop_limit 2000
	for ( i = 0; i < depth; i = i + 1 )
		begin
			if ( en[i] && ~cs_n && ~wr_n )
				//synthesis loop_limit 2000
				for ( k = 0; k < data_width; k = k + 1 )
					data_int1[i * data_width + k] = data_in[k];
			else
				//synthesis loop_limit 2000
				for ( k = 0; k < data_width; k = k + 1 )
					data_int1[i * data_width + k] = mem2[i * data_width + k];		
		end

//Update the data_out		
always @( rd1_addr or out1 )
	if (rd1_addr > depth-1 ) 
		data_rd1_out = 0;
	else 
		data_rd1_out = out1;

always @( rd2_addr or out2 )
	if (rd2_addr > depth-1) 
		data_rd2_out = 0;
	else 
		data_rd2_out = out2;

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
