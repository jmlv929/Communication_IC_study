
//--------------------------------------------------------------------------------------------------
//
// Title       : DW_ram_rw_s_lat
// Design      : DW_ram_rw_s_lat


//
//-------------------------------------------------------------------------------------------------
// Description : DW_ram_rw_s_dff implements a parameterized, synchronous, single-port static RAM.
// The write operation of the RAM is fully synchronous with respect to the clock, clk. The read 
// operation is asynchronous to the clock, allowing the data written into the RAM to be instantly 
// read. The write data enters the RAM through the data_in input port, and is read out through the
// data_out port. The cs_n input is the chip select, active low signal that enables the RAM. When 
// cs_n is LOW, data is constantly read from the RAM. When wr_n, the active low write enable, is
// LOW, and cs_n is LOW, data is written into the RAM on the rising edge of clk.
//-------------------------------------------------------------------------------------------------
module DW_ram_rw_s_lat (clk, cs_n, wr_n, rw_addr, data_in, data_out)/* synthesis syn_builtin_du = "weak" */;

parameter data_width = 8;
parameter depth = 16;

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

//Input/output declaration
input [data_width - 1 : 0]       data_in;
input 							 clk;       
input 							 cs_n;      
input 							 wr_n;      
input [`_synp_bit_width - 1 : 0] rw_addr;
output [data_width - 1 : 0]      data_out;

//Signal declaration
reg [data_width - 1 : 0]         data_out;
reg [data_width * depth - 1 : 0] mem;
reg [data_width * depth - 1 : 0] data_int;
wire [depth - 1 : 0]             en;
wire [data_width - 1 : 0]         out;
integer 						 i; 
integer 	 					 j;
integer 						 k; 

        //Output MUX instantiation	
        DW01_mux_any #(data_width * depth, `_synp_bit_width, data_width ) out1_mux (.A(mem), .SEL(rw_addr), .MUX(out));

		//address decoder
        assign en = 1'b1 << rw_addr;  

        //Collect the data based on control signals
        always @( en or cs_n or wr_n or data_in or clk or mem )
            //synthesis loop_limit 2000	 
			for ( i = 0; i < depth; i = i + 1 ) 
				begin
					if ( !wr_n && !cs_n && en[i] && !clk )
						begin
							//synthesis loop_limit 2000
							for ( k = 0; k < data_width; k = k + 1 )
								data_int[ i * data_width + k ] = data_in[k];
						end		
					else 
						begin 					  
						    //synthesis loop_limit 2000
							for ( k = 0; k < data_width; k = k + 1 )
								data_int[ i * data_width + k ] = mem [i * data_width + k]; 
						end		
		        end		
		
		//Latch implementation		
		always @( clk or data_int )
			if ( !clk )
				mem = data_int;
				
		//Update the data_out
		always @(cs_n or out or rw_addr)      
		begin                                 
		if ( cs_n  || (rw_addr > depth - 1))  
				data_out = 0;                 
			else                              
			 	data_out = out;               
		end                                   

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
