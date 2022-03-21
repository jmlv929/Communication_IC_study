
//--------------------------------------------------------------------------------------------------
//
// Title       : DW_ram_2r_w_s_lat
// Design      : DW_ram_2r_w_s_lat


//
//-------------------------------------------------------------------------------------------------
// Description : DW_ram_2r_w_s_lat implements a parameterized, synchronous, three-port static RAM 
// consisting of one write port and two read ports. The RAM can perform simultaneous read and write
// operations.
//-------------------------------------------------------------------------------------------------
module DW_ram_2r_w_s_lat( 
	clk,             //Clock 
	cs_n, 			 //Chip select, active low
	wr_n, 			 //Write enable, active low
	rd1_addr, 	     //Read1 address bus
	rd2_addr, 		 //Read2 address bus
	wr_addr, 		 //Write address
	data_in, 		 //Input data bus
	data_rd1_out,    //Output data bus for read1
	data_rd2_out 	 //Output data bus for read2
	)/* synthesis syn_builtin_du = "weak" */;

parameter data_width=8;
parameter depth=16;

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

input 						  clk; 
input 						  cs_n;
input 						  wr_n;
input [`_synp_bit_width-1 :0] rd1_addr;
input [`_synp_bit_width-1 :0] rd2_addr;
input [`_synp_bit_width-1 :0] wr_addr;
input [data_width-1:0]        data_in;

output [data_width-1:0] data_rd1_out;
output [data_width-1:0] data_rd2_out;

//Internal signal decalration
reg [data_width-1:0] 			 data_rd1_out;
reg [data_width-1:0] 			 data_rd2_out;
wire [depth - 1 : 0] 			 en;          
reg [data_width * depth - 1 : 0] mem;
reg [data_width * depth - 1 : 0] data_int;
wire [data_width-1:0] 			 out1; 
wire [data_width-1:0] 			 out2; 
integer 						 i; 
integer 						 k; 

        //Output MUX instantiation	
        DW01_mux_any #(data_width * depth, `_synp_bit_width, data_width ) out1_mux (.A(mem), .SEL(rd1_addr), .MUX(out1));
        DW01_mux_any #(data_width * depth, `_synp_bit_width, data_width ) out2_mux (.A(mem), .SEL(rd2_addr), .MUX(out2));
				
        //address decoder
        assign en = 1'b1 << wr_addr;  

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
				
		//Updating data_rd1_out	
		always @( out1 or cs_n or wr_n or clk or wr_addr or data_in or rd1_addr )	
			if (rd1_addr > depth - 1) 
				data_rd1_out = 0;
			else if (cs_n == 1'b0 && wr_n == 1'b0 && clk == 1'b0 && rd1_addr == wr_addr)
				data_rd1_out = data_in;
			else
				data_rd1_out = out1;
		
		//Updating data_rd2_out		
		always @( out2 or rd2_addr or cs_n or wr_n or clk or wr_addr or data_in )
			if (rd2_addr > depth - 1) 
				data_rd2_out = 0;
			else if (cs_n == 1'b0 && wr_n == 1'b0 && clk == 1'b0 && rd2_addr == wr_addr)
				data_rd2_out = data_in;
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
