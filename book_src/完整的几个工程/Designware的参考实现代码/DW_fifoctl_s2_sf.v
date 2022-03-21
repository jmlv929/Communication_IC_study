
`timescale 1ns/10ps

module	DW_fifoctl_s2_sf
	(
	clk_push,
	clk_pop,
	rst_n,
	push_req_n,
	pop_req_n,
	we_n,
	push_empty,
	push_ae,
	push_hf,
	push_af,
	push_full,
	push_error,
	pop_empty,
	pop_ae,
	pop_hf,
	pop_af,
	pop_full,
	pop_error,
	wr_addr,
	rd_addr,
	push_word_count,
	pop_word_count,
	test
	)/* synthesis syn_builtin_du = "weak" */;

	//Parameter declaration
	parameter 				depth		= 8;
	parameter 				push_ae_lvl	= 2;
	parameter 				push_af_lvl	= 2;
	parameter 				pop_ae_lvl	= 2;
	parameter 				pop_af_lvl	= 2;
	parameter 				err_mode	= 0;
	parameter 				push_sync	= 2;
	parameter 				pop_sync	= 2;
	parameter 				rst_mode	= 0; 
	parameter               tst_mode    = 0;
	  
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
 
 `define _synp_bit_width1 ((depth<16777216)?((depth+1>65536)?((depth+1>1048576)?((depth+1>4194304)?((depth+1>8388608)?24:23):((depth+1>2097152)?22:21)):((depth+1>262144)?((depth+1>524288)?20:19):((depth+1>131072)?18:17))):((depth+1>256)?((depth+1>4096)?((depth+1>16384)?((depth+1>32768)?16:15):((depth+1>8192)?14:13)):((depth+1>1024)?((depth+1>2048)?12:11):((depth+1>512)?10:9))):((depth+1>16)?((depth+1>64)?((depth+1>128)?8:7):((depth+1>32)?6:5)):((depth+1>4)?((depth+1>8)?4:3):((depth+1>2)?2:1))))):25)

    //Input/output declaration
	input 								clk_push;        
	input 								clk_pop;         
	input								rst_n;           
	input								push_req_n;      
	input   							pop_req_n;       
	output   							we_n;            
	output   							push_empty;      
	output   							push_ae;         
	output   							push_hf;         
	output   							push_af;         
	output								push_full;       
	output								push_error;      
	output								pop_empty;       
	output								pop_ae;          
	output								pop_hf;          
	output								pop_af;          
	output								pop_full;        
	output								pop_error;       
	output	[`_synp_bit_width - 1 : 0]	wr_addr;   
	output	[`_synp_bit_width - 1 : 0]	rd_addr;  
	output	[`_synp_bit_width1 - 1 : 0]	    push_word_count;   
	output	[`_synp_bit_width1 - 1 : 0]	    pop_word_count;  
	input								test;       

	//Internal signal declaration
	reg   							we_n;            
	reg   							push_empty;      
	reg   							push_ae;         
	reg   							push_hf;         
	reg   							push_af;         
	reg								push_full;       
	reg								push_error;      
	reg								pop_empty;       
	reg								pop_ae;          
	reg								pop_hf;          
	reg								pop_af;          
	reg								pop_full;        
	reg								pop_error;  
	reg	[`_synp_bit_width - 1 : 0]	wr_addr;   
	reg	[`_synp_bit_width - 1 : 0]	rd_addr;  
   	reg	[`_synp_bit_width1 - 1 : 0]	    push_word_count;   
	reg	[`_synp_bit_width1 - 1 : 0]	    pop_word_count;   
	wire [`_synp_bit_width - 1 : 0]	wr_addr_g;   
	wire [`_synp_bit_width - 1 : 0]	rd_addr_g;  
	wire [`_synp_bit_width - 1 : 0]	wr_addr_b;   
	wire [`_synp_bit_width - 1 : 0]	rd_addr_b;  
	wire [`_synp_bit_width : 0]	    push_word_count_g; 
	wire [`_synp_bit_width : 0]		pop_word_count_g;  
	wire [`_synp_bit_width : 0]	    push_word_count_b; 
	wire [`_synp_bit_width : 0]		pop_word_count_b;  
	
	fifoctl_s2_sf_gray #( depth, push_ae_lvl, push_af_lvl, pop_ae_lvl, pop_af_lvl, err_mode, push_sync, pop_sync, rst_mode ) gray
	(
	.clk_push(clk_push),
	.clk_pop(clk_pop),
	.rst_n(rst_n),
	.push_req_n(push_req_n),
	.pop_req_n(pop_req_n),
	.we_n(we_n_g),
	.push_empty(push_empty_g),
	.push_ae(push_ae_g),
	.push_hf(push_hf_g),
	.push_af(push_af_g),
	.push_full(push_full_g),
	.push_error(push_error_g),
	.pop_empty(pop_empty_g),
	.pop_ae(pop_ae_g),
	.pop_hf(pop_hf_g),
	.pop_af(pop_af_g),
	.pop_full(pop_full_g),
	.pop_error(pop_error_g),
	.wr_addr(wr_addr_g),
	.rd_addr(rd_addr_g),
	.wr_fifo_cnt_out(push_word_count_g),   
	.rd_fifo_cnt_out(pop_word_count_g)  
	);
	
	fifoctl_s2_sf_bin #( depth, push_ae_lvl, push_af_lvl, pop_ae_lvl, pop_af_lvl, err_mode, push_sync, pop_sync, rst_mode ) bin
	(
	.clk_push(clk_push),
	.clk_pop(clk_pop),
	.rst_n(rst_n),
	.push_req_n(push_req_n),
	.pop_req_n(pop_req_n),
	.we_n(we_n_b),
	.push_empty(push_empty_b),
	.push_ae(push_ae_b),
	.push_hf(push_hf_b),
	.push_af(push_af_b),
	.push_full(push_full_b),
	.push_error(push_error_b),
	.pop_empty(pop_empty_b),
	.pop_ae(pop_ae_b),
	.pop_hf(pop_hf_b),
	.pop_af(pop_af_b),
	.pop_full(pop_full_b),
	.pop_error(pop_error_b),
	.wr_addr(wr_addr_b),
	.rd_addr(rd_addr_b),
	.wr_fifo_cnt_out(push_word_count_b),   
	.rd_fifo_cnt_out(pop_word_count_b)  
	);	
	
	always @ ( push_empty_g or push_ae_g or push_hf_g or  push_af_g or push_full_g or push_error_g or pop_empty_g or pop_ae_g or pop_hf_g
		or pop_af_g or pop_full_g or pop_error_g or wr_addr_g or rd_addr_g or push_empty_b or push_ae_b or push_hf_b or push_af_b or push_full_b
		or push_error_b or pop_empty_b or pop_ae_b or  pop_hf_b or pop_af_b or pop_full_b or pop_error_b or wr_addr_b or rd_addr_b or we_n_g or we_n_b
		or push_word_count_g or push_word_count_b or pop_word_count_g or pop_word_count_b)
		if ( depth == 4 || depth == 8 || depth == 16 || depth == 32 || depth == 64 || depth == 128 || depth == 256 || depth == 512 || depth == 1024 || depth == 2048 || depth == 4096 || depth == 8192 || depth == 16384 || depth == 32768 || depth == 65536 || depth == 131072 ||  depth == 262144 ||  depth == 524288 ||  depth == 1048576 || depth == 2097152 ||  depth == 4194304 || depth == 8288608 || depth == 16777216)  
			begin
				push_empty = push_empty_g;
				push_ae = push_ae_g;
				push_hf = push_hf_g;
				push_af = push_af_g;
				push_full =push_full_g;
				push_error =push_error_g;
				pop_empty = pop_empty_g;
				pop_ae = pop_ae_g;
				pop_hf = pop_hf_g;
				pop_af = pop_af_g;
				pop_full = pop_full_g;
				pop_error = pop_error_g;
				wr_addr = wr_addr_g;
				rd_addr = rd_addr_g ;
				we_n = we_n_g;
				push_word_count = push_word_count_g;
				pop_word_count = pop_word_count_g;
			end
		else   
			begin
				push_empty = push_empty_b;
				push_ae = push_ae_b;
				push_hf = push_hf_b;
				push_af = push_af_b;
				push_full =push_full_b;
				push_error =push_error_b;
				pop_empty = pop_empty_b;
				pop_ae = pop_ae_b;
				pop_hf = pop_hf_b;
				pop_af = pop_af_b;
				pop_full = pop_full_b;
				pop_error = pop_error_b;
				wr_addr = wr_addr_b;
				rd_addr = rd_addr_b;
				we_n = we_n_b;
				push_word_count = push_word_count_b;
				pop_word_count = pop_word_count_b;
			end	
				
`undef _synp_bit_width
`undef _synp_bit_width1
`undef _synp_dep
`undef C0
`undef C1
`undef C2
`undef C3
`undef C4
`undef C5
`undef C2BITS

endmodule
