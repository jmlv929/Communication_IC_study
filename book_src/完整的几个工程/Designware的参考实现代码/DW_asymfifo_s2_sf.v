
//--------------------------------------------------------------------------------------------------
// Title       : DW_asymfifo_s2_sf.v
// Design      : examples


// Fixes			 : If depth is odd then depth + 1 should be passed to Memory --Nithin
//-------------------------------------------------------------------------------------------------
// Description : DW_asymfifo_s2_sf is an asymmetric I/O dual independent clock FIFO. It combines the
// DW_asymfifoctl_s2_sf FIFO controller and the DW_ram_r_w_s_dff flip-flop-based RAM. 
//
// The FIFO provides parameterized input data width, output data width, depth, and a full complement
// of flags (full, almost full, half full, almost empty, empty, and error) for both clock systems.
//-------------------------------------------------------------------------------------------------
`timescale 1ns / 10ps
module DW_asymfifo_s2_sf  ( 
							 clk_push,     
							 clk_pop,    
							 rst_n,       
							 push_req_n,
							 flush_n,  
							 pop_req_n,   
							 data_in,
							 push_empty,
							 push_ae,
							 push_hf,
							 push_af,
							 push_full,
							 ram_full,
							 part_wd,
							 push_error,
							 pop_empty,            
							 pop_ae,     
							 pop_hf,
							 pop_af,
							 pop_full,
							 pop_error,
							 data_out											 
						     )/* synthesis syn_builtin_du = "weak" */;


    		//Parameter declaration
			parameter		 	data_in_width	= 16;  
			parameter		 	data_out_width	= 8;
  			parameter 			depth			= 16;
			parameter		 	push_ae_lvl		= 2;
			parameter		 	push_af_lvl		= 2;
			parameter		 	pop_ae_lvl		= 2;
			parameter		 	pop_af_lvl		= 2;
			parameter		 	err_mode		= 0; 
			parameter		 	push_sync		= 2; 
			parameter		 	pop_sync		= 2;			       
			parameter		 	rst_mode		= 1;        
			parameter		 	byte_order		= 0;  			       					
			      				    
  			//Internal parameter decalration									   				    
			parameter w1 = data_in_width;  				    
			parameter w2 = data_out_width; 				    
												   				    
			parameter  k1 = w1/w2;							    
			parameter  k2 = w2/w1;								

		   //implementing log2(depth)                                                  
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
			input								clk_pop;
 			input 								clk_push;
			input 								rst_n;     
			input								push_req_n;
			input								pop_req_n; 
			input	[data_in_width - 1 : 0]		data_in;   
 		    input								flush_n;  

			output [data_out_width - 1 : 0]	   	data_out;
			output								ram_full;
			output								part_wd; 
			output		 						push_full;
			output		 						pop_full;
			output		 						push_af; 
			output		 						pop_af;  
			output		 						push_hf; 
			output								pop_hf;  
			output		 						pop_ae;  
			output		 						push_ae; 
			output		 						pop_empty;
			output		 						push_empty;
			output		 						pop_error;
			output		 						push_error;
			
	//Internal parameter declaration
	parameter rst_mode_ctl = ( rst_mode == 0 ||  rst_mode == 2 ) ? 0 : 1;
	parameter rst_mode_ram = ( rst_mode == 0 ||  rst_mode == 2 ) ? 0 : 1;
	parameter width = w1 > w2 ? w1 : w2;
	//Internal signal declaration
	wire [(`_synp_bit_width - 1) : 0]            wr_addr;                           
	wire [(`_synp_bit_width - 1) : 0]            rd_addr;                           
	wire [((w1 > w2)? w1 : w2) - 1 : 0]          rd_data;   
	wire [((w1 > w2)? w1 : w2) - 1 : 0]          wr_data;
	wire [data_out_width - 1 : 0]                data_out;	 
	reg                                          reset;

	parameter	depth_mem = depth + depth %2;
	
	//FIFO control		
	DW_asymfifoctl_s2_sf #( data_in_width, data_out_width, depth, push_ae_lvl, push_af_lvl, pop_ae_lvl, pop_af_lvl, err_mode, push_sync, pop_sync, rst_mode_ctl, byte_order ) ctrl (
							 .clk_push(clk_push),   
							 .clk_pop(clk_pop),    
							 .rst_n(rst_n),      
							 .push_req_n(push_req_n), 
							 .flush_n(flush_n),	 
							 .pop_req_n(pop_req_n),  
							 .data_in(data_in),    
							 .rd_data(rd_data),    
							 .we_n(we_n),       
							 .push_empty(push_empty), 
							 .push_ae(push_ae),   
							 .push_hf(push_hf),    
							 .push_af(push_af),   
							 .push_full(push_full),  
							 .ram_full(ram_full),  
							 .part_wd(part_wd),  
							 .push_error(push_error),
							 .pop_empty(pop_empty),  
							 .pop_ae(pop_ae),    
							 .pop_hf(pop_hf),     
							 .pop_af(pop_af),    
							 .pop_full(pop_full), 
							 .pop_error(pop_error),  
							 .wr_data(wr_data),    
							 .wr_addr(wr_addr),    
							 .rd_addr(rd_addr),    
							 .data_out(data_out)
							 );	   
							 
//RAM instantiation
DW_ram_r_w_s_dff
				  #( width, depth_mem, rst_mode_ram  )
			ram	(
           .clk(clk_push), 
				   .rst_n(reset),
				   .cs_n(1'b0), 
				   .wr_n(we_n), 
				   .rd_addr(rd_addr), 
				   .wr_addr(wr_addr),
				   .data_in(wr_data), 
				   .data_out(rd_data)
				   );

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
