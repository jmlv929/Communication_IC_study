
//--------------------------------------------------------------------------------------------------
//
// Title       : async_fifoctl_bin
// Design      : async_fifoctl_bin


//-------------------------------------------------------------------------------------------------
//
// Description : DW_fifoctl_s2_sf is a dual independent clock FIFO RAM controller. It is designed to 
// interface with a dual-port synchronous RAM. The RAM must have:
//   A synchronous write port and An asynchronous read port.
//
// The FIFO controller provides address generation, write enable logic, flag logic, and operational
// error detection logic. Always use depth values that are powers of 2, (i.e. 8, 16, 32, 64, etc) to 
// ensure accurate and predictable status flag behavior. For depth values that are not a power of 2,
// logic controlling the FIFO must use the flags for flow control on a cycle-by-cycle basis. 
//
//------------------------------------------------------------------------------------------------
// Fixes  : Fix for pop_ae. Removed checking of pop_empty in this case. This is not required
//          This could be valid if done combinatorially. Since this is registered, if the clock is
//					is lost when pop_empty is high, the pop_ae remains high till sync stages when clock is
//					recovered. And pop_full, push_ae  --Nithin

`timescale 1ns/10ps

module	async_fifoctl_bin
	(
	clk_push,
	clk_pop,
	rst_n,
	push_req_n,
	pop_req_n, 
	write_allow,
	flush_n, 
	part_wd,
	ren,  
	we_n,
	push_empty,
	push_ae,
	push_hf,
	push_af,
	push_full, 
	ram_full,
	cnt,
	push_error,
	ram_error,
	pop_empty,
	pop_ae,
	pop_hf,
	pop_af,
	pop_full,
	pop_error,
	wr_addr,
	rd_addr
	)/* synthesis syn_builtin_du = "weak" */;

	//Parameter declaration
	parameter 		depth		= 64;
	parameter 		push_ae_lvl	= 2;
	parameter 		push_af_lvl	= 3;
	parameter 		pop_ae_lvl	= 3;
	parameter 		pop_af_lvl	= 3;
	parameter 		err_mode	= 1;
	parameter 		push_sync	= 2;
	parameter 		pop_sync	= 2;
	parameter 		rst_mode	= 0; 
	parameter       w_ratio     = 2;  
	parameter		cnt_w       = 2;

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
	input 								clk_push;        
	input 								clk_pop;         
	input								rst_n;           
	input								push_req_n;      
	input   							pop_req_n;       
	input                               write_allow;
	input                               flush_n;
	input                               part_wd;
	input                               ren;
	input [cnt_w - 1 : 0]               cnt;
	output   							we_n;            
	output   							push_empty;      
	output   							push_ae;         
	output   							push_hf;         
	output   							push_af;         
	output								push_full;       
	output								ram_full;       
	output								push_error;      
	output								ram_error;      
	output								pop_empty;       
	output								pop_ae;          
	output								pop_hf;          
	output								pop_af;          
	output								pop_full;        
	output								pop_error;       
	output	[`_synp_bit_width - 1 : 0]	wr_addr;   
	output	[`_synp_bit_width - 1 : 0]	rd_addr;  
 
    //Internal register declaration	 
	//All pointers are _synp_bit_width + 1 size
	wire 							    read_allow;
	wire [`_synp_bit_width - 1 : 0] 	rd_ptr_b;     
	reg [`_synp_bit_width - 1 : 0]  	rd_ptr_bs;    
	reg [`_synp_bit_width - 1 : 0]  	rd_ptr_ba;    
	reg [`_synp_bit_width - 1 : 0]  	rd_ptr_nxt_b; 
	wire [`_synp_bit_width - 1 : 0] 	rd_ptr_b1;    
	reg [`_synp_bit_width - 1 : 0]  	rd_ptr_b1_s;  
	reg [`_synp_bit_width - 1 : 0]  	rd_ptr_b1_a;  
	wire [`_synp_bit_width - 1 : 0] 	rd_ptr_b2;    
	reg [`_synp_bit_width - 1 : 0]  	rd_ptr_b2_s;  
	reg [`_synp_bit_width - 1 : 0]  	rd_ptr_b2_a;  
	wire [`_synp_bit_width - 1 : 0] 	rd_ptr_bw;    
	wire [`_synp_bit_width - 1 : 0] 	rd_fifo_cnt;  
	wire [`_synp_bit_width - 1 : 0]     rd_fifo_cnt_r;
	reg [`_synp_bit_width  - 1 : 0]     rd_fifo_cnt_rs;
	reg [`_synp_bit_width  - 1 : 0]     rd_fifo_cnt_ra;
	wire                            	pop_empty;                  
	reg                             	pop_empty_s;                
	reg                             	pop_empty_a;                
	wire 								pop_ae;                     
	reg 								pop_ae_s;                   
	reg 								pop_ae_a;                   
	wire 								pop_hf;                     
	reg 								pop_hf_s;                   
	reg 								pop_hf_a;                   
	wire 								pop_af;                     
	reg 								pop_af_s;                   
	reg 								pop_af_a;                   
	wire 								pop_full;                   
	reg 								pop_full_s;                 
	reg 								pop_full_a;                 
	wire 								pop_err;                    
	wire 								pop_error;                  
	reg 								pop_error_s;                
	reg 								pop_error_a;                
	wire [`_synp_bit_width - 1 : 0]	    rd_addr_b;   
	reg [`_synp_bit_width - 1 : 0]  	wr_ptr_bs;      
	reg [`_synp_bit_width - 1 : 0]  	wr_ptr_ba;      
	wire [`_synp_bit_width - 1 : 0] 	wr_ptr_b;       
	reg [`_synp_bit_width - 1 : 0]  	wr_ptr_nxt_b;   
	wire [`_synp_bit_width - 1 : 0] 	wr_ptr_b1;      
	reg [`_synp_bit_width - 1 : 0]  	wr_ptr_b1_s;    
	reg [`_synp_bit_width - 1 : 0]  	wr_ptr_b1_a;    
	wire [`_synp_bit_width - 1 : 0] 	wr_ptr_b2;      
	reg [`_synp_bit_width - 1 : 0]  	wr_ptr_b2_s;    
	reg [`_synp_bit_width - 1 : 0]  	wr_ptr_b2_a;    
	wire [`_synp_bit_width - 1 : 0] 	wr_ptr_br;      
	wire [`_synp_bit_width - 1 : 0] 	wr_fifo_cnt;    
	wire [`_synp_bit_width - 1 : 0]     wr_fifo_cnt_r;
	reg [`_synp_bit_width - 1 : 0]      wr_fifo_cnt_rs;
	reg [`_synp_bit_width - 1 : 0]      wr_fifo_cnt_ra;
	wire [`_synp_bit_width - 1 : 0] 	wr_ptr_nxt_br;            
	wire 								push_full;                
	reg 								push_full_s;              
	reg 								push_full_a;              
	wire 								ram_full;                 
	reg 								ram_full_s;               
	reg 								ram_full_a;               
	wire 								push_empty;               
	reg 								push_empty_s;             
 	reg 								push_empty_a;             
	wire 								push_ae;                  
	reg 								push_ae_s;                
	reg 								push_ae_a;                
	wire 								push_hf;                  
	reg 								push_hf_s;                
	reg 								push_hf_a;                
	wire 								push_af;                  
	reg 								push_af_s;                
	reg 								push_af_a;                
	wire 								push_err;                 
	wire 								push_error;               
	reg 								push_error_s;             
	reg 								push_error_a;             
	wire 								ram_err;                  
	reg 								ram_error_s;              
	reg 								ram_error_a;              
	wire [`_synp_bit_width - 1 : 0]		wr_addr_br;               
	
	//Output assignment
	assign we_n = ~write_allow;
	//Control signals deciding read and write - active high signals
	assign  read_allow = ren;
		
	//sync the bin coded pop pointer to the push clock domain
	//Sync reset
	always @ ( posedge clk_push )
		if ( !rst_n )
			begin 
				rd_ptr_b1_s <= 0;
				rd_ptr_b2_s <= 0;
			end
		else
			begin
				rd_ptr_b1_s <= rd_ptr_b;
				rd_ptr_b2_s <= rd_ptr_b1_s;
			end	
			
	//Aync reset	
	always @ ( posedge clk_push or negedge rst_n )
		if ( !rst_n )
			begin 
				rd_ptr_b1_a <= 0;
				rd_ptr_b2_a <= 0;
			end
		else
			begin
				rd_ptr_b1_a <= rd_ptr_b;
				rd_ptr_b2_a <= rd_ptr_b1_a;
			end							  
	
	assign rd_ptr_b1 = rst_mode ? rd_ptr_b1_s : rd_ptr_b1_a;
	assign rd_ptr_b2 = rst_mode ? rd_ptr_b2_s : rd_ptr_b2_a;
	assign rd_ptr_bw = ( push_sync == 1 ) ?  rd_ptr_b1 : rd_ptr_b2;
	
	// sync the gray coded push pointer to the pop clock domain 
	always @ ( posedge clk_pop )
		if ( !rst_n )
			begin
				wr_ptr_b1_s <= 0;
				wr_ptr_b2_s <= 0;
			end
		else
			begin
				wr_ptr_b1_s <= wr_ptr_b;
				wr_ptr_b2_s <= wr_ptr_b1_s;
			end
			
	always @ ( posedge clk_pop or negedge rst_n )
		if ( !rst_n )
			begin
				wr_ptr_b1_a <= 0;
				wr_ptr_b2_a <= 0;
			end
		else
			begin
				wr_ptr_b1_a <= wr_ptr_b;
				wr_ptr_b2_a <= wr_ptr_b1_a;
			end

	assign wr_ptr_b1 = rst_mode ? wr_ptr_b1_s : wr_ptr_b1_a;
	assign wr_ptr_b2 = rst_mode ? wr_ptr_b2_s : wr_ptr_b2_a;
	assign wr_ptr_br = ( pop_sync == 1 ) ? wr_ptr_b1 : wr_ptr_b2;		
	
	//Generation of rd_ptr and read_addr
	always @( posedge clk_pop )
		if (!rst_n)
			rd_ptr_bs <= 0;
		else
			rd_ptr_bs <= read_allow ? rd_ptr_nxt_b : rd_ptr_bs;
			
	//Async reset		
	always @( posedge clk_pop or negedge rst_n )
		if (!rst_n)
			rd_ptr_ba <= 0;
		else
			rd_ptr_ba <= read_allow ? rd_ptr_nxt_b : rd_ptr_ba;
			
	assign rd_ptr_b = rst_mode ? rd_ptr_bs : rd_ptr_ba;		
		
	//Incrementing pointer
	always	@( read_allow or rd_ptr_b )
		if ( read_allow ) 
			begin
				if ( rd_ptr_b == depth ) 
					rd_ptr_nxt_b = 0;
				else
					rd_ptr_nxt_b = rd_ptr_b + read_allow;
			end		
		else
			rd_ptr_nxt_b = rd_ptr_b;  
				
	// Memory read-address pointer
	assign rd_addr = rd_ptr_b;	   
	
	/*****************************************************************
	                               POP clock domain
	*****************************************************************/
			  
	// FIFO empty on reset or when rd_ptr_nxt_b == wr_ptr_br (synchronized wr_ptr)
	always @(posedge clk_pop )
		if (!rst_n) 
			pop_empty_s <= 1'b1;
		else 
			pop_empty_s <= (rd_ptr_nxt_b == wr_ptr_br);

 	//Async reset
	always @(posedge clk_pop or negedge rst_n )
		if (!rst_n) 
			pop_empty_a <= 1'b1;
		else 
			pop_empty_a <= (rd_ptr_nxt_b == wr_ptr_br);
			
	assign pop_empty = rst_mode ? pop_empty_s : pop_empty_a;		
	
	//Implementing pop_ae, pop_hf and pop_af flags			
	//FIFO count 		
    assign rd_fifo_cnt = wr_ptr_br < rd_ptr_nxt_b ? (depth + 1 + wr_ptr_br - rd_ptr_nxt_b): wr_ptr_br - rd_ptr_nxt_b;	
	//FIFO count on read side		
	always @(posedge clk_pop )
		if (!rst_n) 
			rd_fifo_cnt_rs <= 0;
		else 
			rd_fifo_cnt_rs <= rd_fifo_cnt;
			
	//Async reset 
	always @(posedge clk_pop or negedge rst_n)
		if (!rst_n) 
			rd_fifo_cnt_ra <= 0;
		else 
			rd_fifo_cnt_ra <= rd_fifo_cnt;
		
	assign rd_fifo_cnt_r = rst_mode ? rd_fifo_cnt_rs : rd_fifo_cnt_ra;
			
	  //Generation of pop_ae, pop_hf and pop_af					
	  //Generation of almost_empty flag
	  always @(posedge clk_pop) 
		  if (!rst_n) 
			  pop_ae_s <= 1'b1;           	 
		  else
//			  pop_ae_s <= pop_empty ? 1 : ( rd_fifo_cnt <= pop_ae_lvl );
			  pop_ae_s <= ( rd_fifo_cnt <= pop_ae_lvl );
			  
		//Async reset  
	  always @(posedge clk_pop or negedge rst_n) 
		  if (!rst_n) 
			  pop_ae_a <= 1'b1;           	 
		  else
//			  pop_ae_a <= pop_empty ? 1 : ( rd_fifo_cnt <= pop_ae_lvl );
			  pop_ae_a <= ( rd_fifo_cnt <= pop_ae_lvl );
			  
		assign pop_ae = rst_mode ? pop_ae_s : pop_ae_a;
				  
	  //Generation of half_full flag
	  always @(posedge clk_pop)
		  if (!rst_n) 
			  pop_hf_s <= 1'b0;           	 
		  else 
			  pop_hf_s <= ( rd_fifo_cnt >= (depth + 1)/2 ) & !pop_ae;
				  
	  //Async reset
	  always @(posedge clk_pop or negedge rst_n)
		  if (!rst_n) 
			  pop_hf_a <= 1'b0;           	 
		  else 
			  pop_hf_a <= ( rd_fifo_cnt >= (depth + 1)/2 ) & !pop_ae;
			  
	  assign pop_hf = rst_mode ? pop_hf_s : pop_hf_a;		  
				  
	  //Generation of almost_full flag
	  always @(posedge clk_pop) 
		  if (!rst_n) 
			  pop_af_s <= 1'b0;           	 
		  else 
			  pop_af_s <= ( rd_fifo_cnt >= depth - pop_af_lvl ) & pop_hf;
 	
	  always @(posedge clk_pop or negedge rst_n) 
		  if (!rst_n) 
			  pop_af_a <= 1'b0;           	 
		  else 
			  pop_af_a <= ( rd_fifo_cnt >= depth - pop_af_lvl )& pop_hf;
 	
	  assign pop_af = rst_mode ? pop_af_s : pop_af_a; 
			  
	  //Generation of almost_full flag
	  always @(posedge clk_pop) 
		  if (!rst_n) 
			  pop_full_s <= 1'b0;           	 
		  else 
			  pop_full_s <= ( rd_fifo_cnt == depth ); // & pop_af;
			 
	  //Async reset 
	  always @(posedge clk_pop or negedge rst_n) 
		  if (!rst_n) 
			  pop_full_a <= 1'b0;           	 
		  else 
			  pop_full_a <= ( rd_fifo_cnt == depth ); // & pop_af;

	  assign pop_full = rst_mode ? pop_full_s : pop_full_a;		  
			  
	  //Error generation
	  assign pop_err =  pop_empty & ~pop_req_n ;
	  
	  always @(posedge clk_pop) 
		  if (!rst_n) 
			  pop_error_s <= 1'b0;           	 
		  else 		   
			  begin
				  if ( err_mode )
					  pop_error_s <= pop_err;
				  else if ( pop_err )
					  pop_error_s <= 1'b1;
			  end

	  always @(posedge clk_pop or negedge rst_n) 
		  if (!rst_n) 
			  pop_error_a <= 1'b0;           	 
		  else 		   
			  begin
				  if ( err_mode )
					  pop_error_a <= pop_err;
				  else if ( pop_err )
					  pop_error_a <= 1'b1;
			  end				 
			  
	  assign pop_error = rst_mode ? pop_error_s : pop_error_a;		  
			  
	/*****************************************************************
	                               PUSH clock domain
	*****************************************************************/
		  
	//Wr_ptr and wr_addr generation
	always @( posedge clk_push )
		if (!rst_n)
			wr_ptr_bs <= 0;
		else
			wr_ptr_bs <= write_allow ? wr_ptr_nxt_b : wr_ptr_bs;
			
	//Async reset		
	always @( posedge clk_push or negedge rst_n )
		if (!rst_n)  
			wr_ptr_ba <= 0;
		else
			wr_ptr_ba <= write_allow ? wr_ptr_nxt_b : wr_ptr_ba;
			
	assign 	wr_ptr_b = rst_mode ? wr_ptr_bs : wr_ptr_ba;
	
	//Incrementing pointer
	always	@( write_allow or wr_ptr_b )
		if ( write_allow )
			begin
				if ( wr_ptr_b == depth )
					wr_ptr_nxt_b = 0;
				else
					wr_ptr_nxt_b = wr_ptr_b + write_allow;
			end		
		else
			wr_ptr_nxt_b = wr_ptr_b;	   
			
				
	// Memory write-address pointer
    assign wr_addr = wr_ptr_b;
 	
	//ram_full generation
	wire full_combo = push_af && ( wr_fifo_cnt == depth );
	always @(posedge clk_push )
		if (!rst_n) 
			ram_full_s <= 0;
		else 
			ram_full_s <= full_combo;

	//Async reset		
	always @(posedge clk_push or negedge rst_n)
		if (!rst_n) 
			ram_full_a <= 0;
		else 
			ram_full_a <= full_combo;
			
	assign ram_full = rst_mode ? ram_full_s : ram_full_a;			

	  //FIFO full = ram_full && buffer_full
	  always @(posedge clk_push) 
      if (!rst_n) 
        push_full_s <= 1'b0;           	 
      else 
	  begin
		  if ( w_ratio == 2 )
			  begin
				  if  ( !full_combo )
					  push_full_s <= 1'b0;
				  else if ( (ram_full && cnt == 0 && !push_req_n) || (full_combo && !flush_n) )
					  push_full_s <= 1;										
				   	  
			  end
		   else
			  begin
				   if  ( !full_combo )
					  push_full_s <= 1'b0;
				   else if ( (ram_full && cnt == (w_ratio - 2) && !push_req_n) || (full_combo && !flush_n) )  
					  push_full_s <= 1;
			  end
		end	  
		
	  always @(posedge clk_push or negedge rst_n) 
      if (!rst_n) 
        push_full_a <= 1'b0;           	 
      else 
	  begin
		  if ( w_ratio == 2 )
			  begin
				  if  ( !full_combo )
					  push_full_a <= 1'b0;
				  else if ( (ram_full && cnt == 0 && !push_req_n) || (full_combo && !flush_n) )
					  push_full_a <= 1;										
			  end
		   else
			  begin
				   if  ( !full_combo )
					  push_full_a <= 1'b0;
				   else if ( (ram_full && cnt == (w_ratio - 2) && !push_req_n) || (full_combo && !flush_n) )  
					  push_full_a <= 1;
			  end
		end	  
 
	assign push_full = rst_mode ? push_full_s : push_full_a;	

	//converting sync. read ptr to binary
	assign wr_fifo_cnt = wr_ptr_nxt_b < rd_ptr_bw ? ( depth + 1 + wr_ptr_nxt_b - rd_ptr_bw ) : wr_ptr_nxt_b - rd_ptr_bw;
	//FIFO count on write side		
	always @(posedge clk_push)
		if (!rst_n) 
			wr_fifo_cnt_rs <= 0;
		else 
			wr_fifo_cnt_rs <= wr_fifo_cnt;
			
	//Async reset		
	always @(posedge clk_push or negedge rst_n)
		if (!rst_n) 
			wr_fifo_cnt_ra <= 0;
		else 
			wr_fifo_cnt_ra <= wr_fifo_cnt;
			
	assign wr_fifo_cnt_r = rst_mode ? wr_fifo_cnt_rs : wr_fifo_cnt_ra; 		

	//Generation of almost_empty flag
	  always @(posedge clk_push ) 
		  if (!rst_n) 
			  push_ae_s <= 1'b1;           	 
		  else
	//		  push_ae_s <= push_empty ? 1 : ( wr_fifo_cnt <= push_ae_lvl );
			  push_ae_s <= ( wr_fifo_cnt <= push_ae_lvl );
			  
	  //Async reset	  
	  always @(posedge clk_push or negedge rst_n) 
		  if (!rst_n) 
			  push_ae_a <= 1'b1;           	 
		  else
//			  push_ae_a <= push_empty ? 1 : ( wr_fifo_cnt <= push_ae_lvl );
			  push_ae_a <= ( wr_fifo_cnt <= push_ae_lvl );
			  
	  assign push_ae = rst_mode ? push_ae_s : push_ae_a;
			  
	  //Generation of half_full flag
	  always @(posedge clk_push)
		  if (!rst_n) 
			  push_hf_s <= 1'b0;           	 
		  else 
			  push_hf_s <= ( wr_fifo_cnt >= (depth + 1)/2 ) & !push_ae;
				  
	  always @(posedge clk_push or negedge rst_n )
		  if (!rst_n) 
			  push_hf_a <= 1'b0;           	 
		  else 
			  push_hf_a <= ( wr_fifo_cnt >= (depth + 1)/2 ) & !push_ae;
				  
	  assign push_hf = rst_mode ? push_hf_s : push_hf_a;
	  
	  //Generation of almost_full flag
	  always @(posedge clk_push) 
		  if (!rst_n) 
			  push_af_s <= 1'b0;           	 
		  else 
			  push_af_s <= ( wr_fifo_cnt >= depth - push_af_lvl ) & push_hf;
			  
	  always @(posedge clk_push or negedge rst_n) 
		  if (!rst_n) 
			  push_af_a <= 1'b0;           	 
		  else 
			  push_af_a <= ( wr_fifo_cnt >= depth - push_af_lvl ) & push_hf;

	  assign push_af = rst_mode ? push_af_s : push_af_a;
	  
	  //Generation of almost_full flag
	  always @(posedge clk_push) 
		  if (!rst_n) 
			  push_empty_s <= 1'b1;           	 
		  else 
			  push_empty_s <= (rd_ptr_bw == wr_ptr_nxt_b);
			  
	  always @(posedge clk_push or negedge rst_n) 
		  if (!rst_n) 
			  push_empty_a <= 1'b1;           	 
		  else 
			  push_empty_a <= (rd_ptr_bw == wr_ptr_nxt_b);
			  
	assign push_empty = rst_mode ? push_empty_s : push_empty_a;
	
	//Error generation
	  assign push_err = (push_full & ~push_req_n) | (ram_full & part_wd & ~flush_n);
	  assign ram_err = ram_full & ~push_req_n;
	  
	  always @(posedge clk_push) 
		  if (!rst_n) 
			  push_error_s <= 1'b0;           	 
		  else 		   
			  begin
				  if ( err_mode )
					  push_error_s <= push_err;
				  else if ( push_err )
					  push_error_s <= 1'b1;
			  end		  
					  
	  always @(posedge clk_push or negedge rst_n) 
		  if (!rst_n) 
			  push_error_a <= 1'b0;           	 
		  else 		   
			  begin
				  if ( err_mode )
					  push_error_a <= push_err;
				  else if ( push_err )
					  push_error_a <= 1'b1;
			  end		  

	  always @(posedge clk_push) 
		  if (!rst_n) 	  
				  ram_error_s <= 1'b0;
		  else 		   
			  begin
				  if ( err_mode )
					  ram_error_s <= ram_err;
				  else if ( ram_err )		   
					  ram_error_s <= 1'b1;
			  end		  
					  
	  always @(posedge clk_push or negedge rst_n) 
		  if (!rst_n) 		 
			  ram_error_a <= 1'b0;
		  else 		   
			  begin
				  if ( err_mode )
					  ram_error_a <= ram_err;
				  else if ( ram_err )
					  ram_error_a <= 1'b1;
			  end		  

	   assign push_error = rst_mode ? push_error_s : push_error_a;
	   assign ram_error = rst_mode ? ram_error_s : ram_error_a;
	   
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
