						

//--------------------------------------------------------------------------------------------------
//
// Title       : DW_asymfifoctl_s1_df
// Design      : DW_asymfifoctl_s1_df


//-------------------------------------------------------------------------------------------------
//
// Description : DW_fifoctl_s1_df is a FIFO RAM controller designed to interface with a dual-port
// synchronous RAM.
// The input data bit width of DW_asymfifoctl_s1_df can be different than its output data bit
// width, but must have an integer-multiple relationship (the input bit width being a multiple
// of the output bit width or vice versa). In other words, either of the following conditions
// must be true:
// The data_in_width = K x data_out_width, or
//   The data_out_width = K x data_in_width
// where K is a positive integer.
// The asymmetric FIFO controller provides address generation, write-enable logic, flag logic
// and operational error detection logic.
// 
// The almost_empty and almost_full flags are dynamically set by the ae_level and af_thresh
// inputs.
//-------------------------------------------------------------------------------------------------
// Fixes      : For data_in_width < data_out_width ->
//							1. push_req_n check for last data byte
//							2. Counter reset only if flush and part_wd is present or else even if an 
//								 empty word is written the counter will restart.Reloading counter if simultaneous
//								 push_req
//              3. Deasserting part_wd if full but if there is a pop
//							4. Asserting full flag when fifo was already full and if there is a simultaneous
//								 push, pop & flush
//              -- Nithin

`timescale 1ns/10ps

module DW_asymfifoctl_s1_df (
	clk, 
	rst_n, 
	push_req_n,
	flush_n,
	pop_req_n,
	diag_n,	
	data_in, 
	rd_data,
	ae_level,
	af_thresh,
	we_n, 
	empty, 
	almost_empty,
	half_full,
	almost_full,
	full, 
	ram_full,
	error,
	part_wd, 
	wr_data,
	rd_addr,
	wr_addr, 
	data_out
	)/* synthesis syn_builtin_du = "weak" */;

	parameter data_in_width = 8;
	parameter data_out_width = 16;
	parameter depth = 8;
	parameter err_mode = 1;
	parameter rst_mode = 1; 
	parameter byte_order = 0;	
	
	//Internal parameter declaration
	parameter w1 = data_in_width;
	parameter w2 = data_out_width;
	
	parameter  k1 = (w1 / w2);
	parameter  k2 = (w2 / w1);
   	parameter  k = ( w1 < w2 ) ? (w2 - w1) : (w1 - w2 );
	 
	//log2 implementation for calculating bit width	for addressing RAM
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



	`define _synp_bit_width  `C2BITS    
                                                       
    `define EMPTY_COUNT       {(`_synp_bit_width+1){1'b0}}
    `define FULL_COUNT        depth 
    `define EMPTY_COUNT_P1    (`EMPTY_COUNT + 1)
    `define FULL_COUNT_1      (`FULL_COUNT - 1)

	`define POS0 0+(k2>1)+(k2>2)+(k2>4)+(k2>8)+(k2>16)+(k2>32)+(k2>64)+(k2>128)+(k2>256)                  
	`define K22BITS `POS0                               
	                                                                                    
    `define k2_bit_width `K22BITS

	`define POS00 0+(k1>1)+(k1>2)+(k1>4)+(k1>8)+(k1>16)+(k1>32)+(k1>64)+(k1>128)+(k1>256)                  
	`define K12BITS `POS00                             
	                                                                                    
	`define k1_bit_width `K12BITS 
	
    // Input/output declaration
	input 																			  clk;       
	input 																			  rst_n;     
	input 																			  push_req_n;
	input 																			  pop_req_n; 
	input [data_in_width - 1 : 0] 													  data_in;   
	input [((data_in_width > data_out_width)? data_in_width : data_out_width)-1 : 0]  rd_data;   
	input [(`_synp_bit_width-1):0]                									  ae_level; 
	input [(`_synp_bit_width-1):0]                 									  af_thresh;
	input 																			  flush_n;   
	input 																			  diag_n;    

	output [data_out_width - 1 : 0] 												  data_out;
	output [((data_in_width > data_out_width)? data_in_width : data_out_width)-1 : 0] wr_data;
	output 																			  ram_full; 
	output 																			  part_wd;  
	output [`_synp_bit_width - 1 : 0] 												  wr_addr;
	output [`_synp_bit_width - 1 : 0] 												  rd_addr;
	output 																			  we_n;
	output 																			  full;          
	output 																			  almost_full;   
	output 																			  half_full;     
	output 																			  almost_empty;  
	output 																			  empty;         
	output 																			  error;         

    //Internal signal declarartion 													  
	integer																			  i;
	//Naming convention used - signal_name_xy
	//Where x -> e = equal, l = lesser, g = greater
	//      y -> s = sync, a = async	
	
	// data_in_width == data_out_width signal declaration
	//Synchronous registers
	wire                                    we_n_es;                              
	wire                                    rd_en_es;                             
	reg [(`_synp_bit_width - 1) : 0]        wr_addr_es;                           
	reg [(`_synp_bit_width - 1) : 0]        rd_addr_es;                           
	reg [(`_synp_bit_width + 1 - 1) : 0]    fifo_cnt_es;                          
	reg [(`_synp_bit_width + 1 - 1) : 0]    fifo_cnt_es_r;                        
	reg                                     full_es;                              
	reg                                     empty_es;                             
	reg                                     almost_empty_es;                      
	reg                                     half_full_es;                         
	reg                                     almost_full_es;                       
	reg                                     error_es;                             
	wire                                    push_err_es;                          
	wire                                    pop_err_es;                           
	wire                                    ptr_err_es;
	//Asynchronous registers
	wire                                    we_n_ea;                              
	wire                                    rd_en_ea;                             
	reg [(`_synp_bit_width - 1) : 0]        wr_addr_ea;                           
	reg [(`_synp_bit_width - 1) : 0]        rd_addr_ea;                           
	reg [(`_synp_bit_width + 1 - 1) : 0]    fifo_cnt_ea;                          
	reg [(`_synp_bit_width + 1 - 1) : 0]    fifo_cnt_ea_r;                        
	reg                                     full_ea;                              
	reg                                     empty_ea;                             
	reg                                     almost_empty_ea;                      
	reg                                     half_full_ea;                         
	reg                                     almost_full_ea;                       
	reg                                     error_ea;                             
	wire                                    push_err_ea;                          
	wire                                    pop_err_ea;                           
	wire                                    ptr_err_ea;                           

	wire                                    we_n_e;                              
	wire                                    rd_en_e;                             
	wire [(`_synp_bit_width - 1) : 0]       wr_addr_e;                           
	wire [(`_synp_bit_width - 1) : 0]       rd_addr_e;                           
	wire                                    full_e;                              
	wire                                    empty_e;                             
	wire                                    almost_empty_e;                      
	wire                                    half_full_e;                         
	wire                                    almost_full_e;                       
	wire                                    error_e;                             
	wire [data_out_width - 1 : 0] 			data_out_e;
	wire [data_in_width - 1 : 0] 		    wr_data_e;   

	// data_in_width < data_out_width signal declaration
	//Synchronous registers
	wire                                    we_n_ls;                              
	wire                                    rd_en_ls;                             
	reg [(`_synp_bit_width - 1) : 0]        wr_addr_ls;                           
	reg [(`_synp_bit_width - 1) : 0]        rd_addr_ls;                           
	reg [(`_synp_bit_width + 1 - 1) : 0]    fifo_cnt_ls;                          
	reg [(`_synp_bit_width + 1 - 1) : 0]    fifo_cnt_ls_r;                        
	reg [((w1 == w2) ? 2 : ((w1 < w2)? `k2_bit_width : `k1_bit_width))-1 : 0] cnt_ls_r; 
    reg                                     full_ls;                              
	reg                                     ram_full_ls;                              
	reg                                     empty_ls;
	reg                                     part_wd_ls;                             
	reg                                     almost_empty_ls;                      
	reg                                     half_full_ls;                         
	reg                                     almost_full_ls;                       
	reg                                     error_ls;                             
	wire [data_out_width - 1 : 0] 		    wr_data_ls;   
	wire [data_out_width - 1 : 0] 		    wr_data0_ls;   
	wire [data_out_width - 1 : 0] 		    wr_data1_ls;   
	wire                                    push_err_ls;                          
	wire                                    pop_err_ls;                           
	wire                                    ptr_err_ls;
	reg [((w1 < w2)? (k2 - 1 )* data_in_width : ((w1 == w2 ) ? data_in_width : (k1 - 1 )* data_in_width)) - 1 : 0]	data_hold0_ls_r;
	reg [((w1 < w2)? (k2 - 1 )* data_in_width : ((w1 == w2 ) ? data_in_width : (k1 - 1 )* data_in_width)) - 1 : 0]	data_hold1_ls_r;
	//Asynchronous registers
	wire                                    we_n_la;                              
	wire                                    rd_en_la;                             
	reg [(`_synp_bit_width - 1) : 0]        wr_addr_la;                           
	reg [(`_synp_bit_width - 1) : 0]        rd_addr_la;                           
	reg [(`_synp_bit_width + 1 - 1) : 0]    fifo_cnt_la;                          
	reg [(`_synp_bit_width + 1 - 1) : 0]    fifo_cnt_la_r;                        
	reg [((w1 == w2) ? 2 : ((w1 < w2)? `k2_bit_width : `k1_bit_width))-1 : 0] cnt_la_r; 
	reg                                     full_la;                              
	reg                                     ram_full_la;                              
	reg                                     empty_la;                             
	reg                                     almost_empty_la;                      
	reg                                     half_full_la;                         
	reg                                     almost_full_la;                       
	reg                                     error_la;                             
	reg                                     part_wd_la;                             
	wire [data_out_width - 1 : 0] 		    wr_data_la;   
	wire [data_out_width - 1 : 0] 		    wr_data0_la;   
	wire [data_out_width - 1 : 0] 		    wr_data1_la;   
	wire                                    push_err_la;                          
	wire                                    pop_err_la;                           
	wire                                    ptr_err_la;                           
	reg [((w1 < w2)? (k2 - 1 )* data_in_width : ((w1 == w2 ) ? data_in_width : (k1 - 1 )* data_in_width)) - 1 : 0]	data_hold0_la_r;
	reg [((w1 < w2)? (k2 - 1 )* data_in_width : ((w1 == w2 ) ? data_in_width : (k1 - 1 )* data_in_width)) - 1 : 0]	data_hold1_la_r;

	wire                                    we_n_l;                              
	wire                                    rd_en_l;                             
	wire [(`_synp_bit_width - 1) : 0]       wr_addr_l;                           
	wire [(`_synp_bit_width - 1) : 0]       rd_addr_l;                           
	wire [((w1 == w2) ? 2 : ((w1 < w2)? `k2_bit_width : `k1_bit_width))-1 : 0] cnt_l; 
	wire                                    full_l;                              
	wire                                    ram_full_l;                              
	wire                                    empty_l;                             
	wire                                    almost_empty_l;                      
	wire                                    half_full_l;                         
	wire                                    almost_full_l;                       
	wire                                    part_wd_l;                             
	wire                                    error_l;                             
	wire [data_out_width - 1 : 0] 			data_out_l;
	wire [data_out_width - 1 : 0] 		    wr_data_l;   

	// data_in_width > data_out_width signal declaration
	//Synchronous registers
	wire                                    we_n_gs;                              
	wire                                    rd_en_gs;                             
	reg [(`_synp_bit_width - 1) : 0]        wr_addr_gs;                           
	reg [(`_synp_bit_width - 1) : 0]        rd_addr_gs;                           
	reg [(`_synp_bit_width + 1 - 1) : 0]    fifo_cnt_gs;                          
	reg [(`_synp_bit_width + 1 - 1) : 0]    fifo_cnt_gs_r;                        
	reg [((w1 == w2) ? 2 : ((w1 < w2) ? `k2_bit_width : `k1_bit_width))-1 : 0] cnt_gs_r; 
	reg [data_out_width - 1 : 0] 			data_out_gs0;
	reg [data_out_width - 1 : 0] 			data_out_gs1;
	wire [data_out_width - 1 : 0] 			data_out_gs;
	reg                                     full_gs;                              
	reg                                     empty_gs;                             
	reg                                     almost_empty_gs;                      
	reg                                     half_full_gs;                         
	reg                                     almost_full_gs;                       
	reg                                     error_gs;                             
	wire                                    push_err_gs;                          
	wire                                    pop_err_gs;                           
	wire                                    ptr_err_gs;
	//Asynchronous registers
	wire                                    we_n_ga;                              
	wire                                    rd_en_ga;                             
	reg [(`_synp_bit_width - 1) : 0]        wr_addr_ga;                           
	reg [(`_synp_bit_width - 1) : 0]        rd_addr_ga;                           
	reg [(`_synp_bit_width + 1 - 1) : 0]    fifo_cnt_ga;                          
	reg [(`_synp_bit_width + 1 - 1) : 0]    fifo_cnt_ga_r;                        
	reg [((w1 == w2) ? 2 : ((w1 < w2)? `k2_bit_width : `k1_bit_width))-1 : 0] cnt_ga_r; 
	reg [data_out_width - 1 : 0] 			data_out_ga0;
	reg [data_out_width - 1 : 0] 			data_out_ga1;
	wire [data_out_width - 1 : 0] 			data_out_ga;
	reg                                     full_ga;                              
	reg                                     empty_ga;                             
	reg                                     almost_empty_ga;                      
	reg                                     half_full_ga;                         
	reg                                     almost_full_ga;                       
	reg                                     error_ga;                             
	wire                                    push_err_ga;                          
	wire                                    pop_err_ga;                           
	wire                                    ptr_err_ga;                           
	wire                                    we_n_g;                              
	wire                                    rd_en_g;                             
	wire [(`_synp_bit_width - 1) : 0]       wr_addr_g;                           
	wire [(`_synp_bit_width - 1) : 0]       rd_addr_g;                           
	wire                                    full_g;                              
	wire                                    empty_g;                             
	wire                                    almost_empty_g;                      
	wire                                    half_full_g;                         
	wire                                    almost_full_g;                       
	wire                                    error_g;                             
	wire [data_out_width - 1 : 0] 			data_out_g;
	wire [data_in_width - 1 : 0] 		    wr_data_g;   
	
	
	//Output assignment
	assign rd_addr = w1 < w2 ? rd_addr_l : ( w1 > w2  ? rd_addr_g : rd_addr_e);
	assign wr_addr = w1 < w2 ? wr_addr_l : ( w1 > w2  ? wr_addr_g : wr_addr_e);
	assign full = w1 < w2 ? full_l : ( w1 > w2  ? full_g : full_e); 
	assign half_full = w1 < w2 ? half_full_l : ( w1 > w2  ? half_full_g : half_full_e); 
	assign almost_full = w1 < w2 ? almost_full_l : ( w1 > w2  ? almost_full_g : almost_full_e); 
	assign empty = w1 < w2 ? empty_l : ( w1 > w2  ? empty_g : empty_e); 
	assign almost_empty = w1 < w2 ? almost_empty_l : ( w1 > w2  ? almost_empty_g : almost_empty_e); 
	assign ram_full = w1 < w2 ? ram_full_l : ( w1 > w2  ? full_g : full_e); 
	assign part_wd =  w1 < w2 ? part_wd_l : 0;
	assign we_n =  w1 < w2 ? we_n_l : ( w1 > w2  ? we_n_g : we_n_e); 
	assign error = w1 < w2 ? error_l : ( w1 > w2  ? error_g : error_e);
	assign data_out = w1 < w2 ? data_out_l : ( w1 > w2  ? data_out_g : data_out_e);
	assign wr_data = w1 < w2 ? wr_data_l : ( w1 > w2  ? wr_data_g : wr_data_e);
	
	
	/*****************************************************
	* Implementation of data_in_width == data_out_width	 * 
	*****************************************************/
	assign rd_addr_e = rst_mode ? rd_addr_es : rd_addr_ea;
	assign wr_addr_e = rst_mode ? wr_addr_es : wr_addr_ea;
	assign full_e = rst_mode ? full_es : full_ea; 
	assign half_full_e = rst_mode ? half_full_es : half_full_ea; 
	assign almost_full_e = rst_mode ? almost_full_es : almost_full_ea; 
	assign empty_e = rst_mode ? empty_es : empty_ea; 
	assign almost_empty_e = rst_mode ? almost_empty_es : almost_empty_ea; 
	assign we_n_e = rst_mode ? we_n_es : we_n_ea; 
	assign error_e = rst_mode ? error_es : error_ea; 
	assign data_out_e = rd_data;
	assign wr_data_e = data_in;
	
    /**************************************
	    Sync. reg implementation										
	***************************************/
   // Generate memory write enable and supply to memory	without flopping. 
   // Writes should only be allowed when the FIFO is not full so that 
   // overflow data is discarded. rd_en is used to control the advancement of 
   // rd_addr and only asserted when the memory is not empty.
    assign we_n_es = push_req_n || full && ~( !push_req_n && !pop_req_n && full_es );
	assign rd_en_es = ~(pop_req_n || empty);

  // Increment the read address only when rd_en is in asserted. The if conditions are pretty
  // explanatory. 
  always @(posedge clk) 
      if (!rst_n) 
        rd_addr_es <= {`_synp_bit_width{1'b0}};           	 
      else 
		  begin
			  if ( err_mode == 0 && !diag_n )
				  rd_addr_es <= 0;
		      else 
				  case (rd_en_es)  
					  1'b0: rd_addr_es <= rd_addr_es;
					  1'b1: if ( rd_addr_es == depth - 1 )
						  rd_addr_es <= 0;	 
					  else
						  rd_addr_es <= rd_addr_es + 1;
				  endcase
          end

   // Increment the write address only when wr_en is asserted. 
   always @(posedge clk) 
      if (!rst_n) 
        wr_addr_es <= {`_synp_bit_width{1'b0}};           	 
      else 
		  begin
			  case (!we_n_es)  
				  1'b0: wr_addr_es <= wr_addr_es;
				  1'b1: if ( wr_addr_es == depth - 1 )
					  wr_addr_es <= 0; 
				  else
					  wr_addr_es <= wr_addr_es + 1;
			  endcase
           end
   
   // Increment or decrement the FIFO count on actual read and/or writes.
   always @(posedge clk) 
      if (!rst_n) 
        fifo_cnt_es_r <= {(`_synp_bit_width+1){1'b0}};           	 
      else 
      	fifo_cnt_es_r <= fifo_cnt_es;
   
   //Combo block
   always @ ( we_n_es or rd_en_es or fifo_cnt_es_r )
     case ({we_n_es, rd_en_es})  
	   2'b10: fifo_cnt_es = fifo_cnt_es_r;
	   2'b00: fifo_cnt_es = fifo_cnt_es_r + 1;	 
	   2'b11: fifo_cnt_es = fifo_cnt_es_r - 1;	 
	   2'b01: fifo_cnt_es = fifo_cnt_es_r;
	 endcase

   // Generate the empty signal based on whether a write and/or read is being allowed
   // and the current state of fifo_cnt. The if conditions are pretty explanatory.
   always @(posedge clk) 
      if (!rst_n) 
        empty_es <= 1'b1;           	 
      else
		  begin
			  if(empty_es & !we_n_es) 
				  empty_es <= 1'b0;
			  else if((fifo_cnt_es_r == `EMPTY_COUNT_P1) & rd_en_es & we_n_es ) 
				  empty_es <= 1'b1;	 
			  else if(fifo_cnt_es_r == `EMPTY_COUNT ) 
				  empty_es <= 1'b1;	 
			  else 
				  empty_es <= 1'b0;
		  end	  

   // Generate the full signal based on whether a write and/or read is being allowed
   // and the current state of fifo_cnt. The if conditions are pretty explanatory.
	  always @(posedge clk) 
      if (!rst_n) 
        full_es <= 1'b0;           	 
      else 
	  begin
         if(full_es & rd_en_es & we_n_es) 
	        full_es <= 1'b0;
	     else if((fifo_cnt_es_r == `FULL_COUNT_1) & !rd_en_es & !we_n_es) 
	        full_es <= 1'b1;	 
	     else if(fifo_cnt_es_r == `FULL_COUNT) 
	        full_es <= 1'b1;	 
	     else 
	        full_es <= 1'b0;	 
      end
   	  
	  //Generation of almost_empty flag
	  always @(posedge clk) 
      if (!rst_n) 
        almost_empty_es <= 1'b1;           	 
      else
		  begin
			  if ( fifo_cnt_es <= ae_level	)
				  almost_empty_es <= 1'b1;
			  else
				  almost_empty_es <= 1'b0;
		  end	
		  
	  //Generation of half_full flag
	  always @(posedge clk) 
      if (!rst_n) 
        half_full_es <= 1'b0;           	 
      else 
	  begin
		  if ( fifo_cnt_es >= (depth + 1)/2 )
			  half_full_es <= 1'b1;
		  else
			  half_full_es <= 1'b0;
	  end	
				  
	  //Generation of almost_full flag
	  always @(posedge clk) 
      if (!rst_n) 
        almost_full_es <= 1'b0;           	 
      else 
	  begin
		  if ( fifo_cnt_es >= af_thresh )
			  almost_full_es <= 1'b1;
		  else
			  almost_full_es <= 1'b0;
	  end	
	  
	  //Error setting based on 
	  //1. Push error: Attempting to write a FIFO when it is FULL ( overflow condition)
	  //2. Pop  error: Attemping to drain the FIFO when it is empty ( underflow condition )
	  //3. Pointer error: wr_addr and rd_addr pointing to different mem. locations when FIFO
	  //                  is either Empty of Full
			assign push_err_es = !push_req_n && full_es && pop_req_n;
			assign pop_err_es = !pop_req_n && empty_es;
			assign ptr_err_es = (empty_es &&(rd_addr_es != wr_addr_es))|| (full_es && (rd_addr_es != wr_addr_es)) || ((rd_addr_es == wr_addr_es)&&(~(full_es || empty_es)));

		//Registering the Error
		always @(posedge clk )                                                                                                                                                                                                     
		if( !rst_n  )
			error_es <= 0;                                                                                                                                                                                                         
		else
			begin
				if( err_mode == 0 )
					begin
						if ( push_err_es || pop_err_es || ptr_err_es )                                                                                                                                                                                          
							error_es <= 1'b1;
					end		
			    else if ( err_mode == 1 )                                                                                                                                                                                            
					begin
						if  ( push_err_es || pop_err_es )
							error_es <= 1'b1;
					end		
				else if ( err_mode == 2 )                                                                                                                                                                                            
					begin
						if ( push_err_es || pop_err_es )
							error_es <= 1'b1;
						else
							error_es <= 1'b0;
					end		
	        end                                                                                                                                                                                                                        

			
   /***********************************************			
				Asynchronous part implementation
   ***********************************************/
   // Generate memory write enable and supply to memory	without flopping. 
   // Writes should only be allowed when the FIFO is not full so that 
   // overflow data is discarded. rd_en is used to control the advancement of 
   // rd_addr and only asserted when the memory is not empty.
   
    assign we_n_ea = ( push_req_n || full_ea ) && ~( !push_req_n && !pop_req_n && full_ea);
	assign rd_en_ea = ~(pop_req_n || empty_ea);

  // Increment the read address only when rd_en is in asserted.The if conditions are pretty
  // explanatory. 
    always @(posedge clk or negedge rst_n ) 
	  if (!rst_n) 
		  rd_addr_ea <= {`_synp_bit_width{1'b0}};           	       
      else 														 
		  begin
			  if ( err_mode == 0 && !diag_n )
				  rd_addr_ea <= 0;
		      else 
				  case (rd_en_ea)  
					  1'b0: rd_addr_ea <= rd_addr_ea;
					  1'b1: if ( rd_addr_ea == depth - 1 )
						  rd_addr_ea <= 0;
					  else
						  rd_addr_ea <= rd_addr_ea + 1;	 
				  endcase
          end

   // Increment the write address only when wr_en is asserted. 
   always @(posedge clk or negedge rst_n) 
      if (!rst_n) 
        wr_addr_ea <= {`_synp_bit_width{1'b0}};           	 
      else
		  begin
			  case (!we_n_ea)  
				  1'b0: wr_addr_ea <= wr_addr_ea;
				  1'b1: if ( wr_addr_ea == depth - 1 )
					  wr_addr_ea <= 0;
				  else
					  wr_addr_ea <= wr_addr_ea + 1;	 
			  endcase
		  end

   // Increment or decrement the FIFO count on actual read and/or writes.
   always @(posedge clk or negedge rst_n) 
      if (!rst_n) 
        fifo_cnt_ea_r <= {(`_synp_bit_width+1){1'b0}};           	       
      else															 
		fifo_cnt_ea_r <= fifo_cnt_ea;  

	//Combo block	
	always @ ( we_n_ea or rd_en_ea or fifo_cnt_ea_r )	  
	 case ({we_n_ea,rd_en_ea})  
	   2'b10: fifo_cnt_ea = fifo_cnt_ea_r;
	   2'b00: fifo_cnt_ea = fifo_cnt_ea_r + 1;	 
	   2'b11: fifo_cnt_ea = fifo_cnt_ea_r - 1;	 
	   2'b01: fifo_cnt_ea = fifo_cnt_ea_r;
	 endcase
 
   // Generate the empty signal based on whether a write and/or read is being allowed
   // and the current state of fifo_cnt. The if conditions are pretty explanatory.
   always @(posedge clk or negedge rst_n) 
      if (!rst_n) 
        empty_ea <= 1'b1;           	 
      else
		  begin
			  if(empty_ea & !we_n_ea) 
				  empty_ea <= 1'b0;
			  else if((fifo_cnt_ea_r == `EMPTY_COUNT_P1) & rd_en_ea & we_n_ea ) 
				  empty_ea <= 1'b1;	 
			  else if(fifo_cnt_ea_r == `EMPTY_COUNT ) 
				  empty_ea <= 1'b1;	 
			  else 
				  empty_ea <= 1'b0;
		  end	  

   // Generate the full signal based on whether a write and/or read is being allowed
   // and the current state of fifo_cnt. The if conditions are pretty explanatory.
	  always @(posedge clk or negedge rst_n) 
      if (!rst_n) 
        full_ea <= 1'b0;           	 
      else 
	  begin
         if(full_ea & rd_en_ea & we_n_ea) 
	        full_ea <= 1'b0;
	     else if((fifo_cnt_ea_r == `FULL_COUNT_1) & !rd_en_ea & !we_n_ea) 
	        full_ea <= 1'b1;	 
	     else if(fifo_cnt_ea_r == `FULL_COUNT) 
	        full_ea <= 1'b1;	 
	     else 
	        full_ea <= 1'b0;	 
      end
   	  
  	  //Generation of almost_empty flag
	  always @(posedge clk or negedge rst_n) 
      if (!rst_n) 
        almost_empty_ea <= 1'b1;           	 
      else
		  begin
			  if ( fifo_cnt_ea <= ae_level	)
				  almost_empty_ea <= 1'b1;
			  else
				  almost_empty_ea <= 1'b0;
		  end	
		  
  	  //Generation of half_full flag
	  always @(posedge clk or negedge rst_n) 
      if (!rst_n) 
        half_full_ea <= 1'b0;           	 
      else 
	  begin
		  if ( fifo_cnt_ea >= (depth + 1)/2 )
			  half_full_ea <= 1'b1;
		  else
			  half_full_ea <= 1'b0;
	  end	
				  
  	  //Generation of almost_full flag
	  always @(posedge clk or negedge rst_n) 
      if (!rst_n) 
        almost_full_ea <= 1'b0;           	 
      else 
	  begin
		  if ( fifo_cnt_ea >= af_thresh )
			  almost_full_ea <= 1'b1;
		  else
			  almost_full_ea <= 1'b0;
	  end	
	  
	  //Error setting based on 
	  //1. Push error: Attempting to write a FIFO when it is FULL ( overflow condition)
	  //2. Pop  error: Attemping to drain the FIFO when it is empty ( underflow condition )
	  //3. Pointer error: wr_addr and rd_addr pointing to different mem. locations when FIFO
	  //                  is either Empty of Full
			assign push_err_ea = !push_req_n && full_ea && pop_req_n;
			assign pop_err_ea = !pop_req_n && empty_ea;
			assign ptr_err_ea = (empty_ea &&(rd_addr_ea != wr_addr_ea))|| (full_ea && (rd_addr_ea != wr_addr_ea)) || ((rd_addr_ea == wr_addr_ea)&&(~(full_ea || empty_ea)));
	  
	  //Error registering
	  always @(posedge clk or negedge rst_n )                                                                                                                                                                                                     
		if( !rst_n  )
			error_ea <= 0;                                                                                                                                                                                                         
		else
			begin
				if( err_mode == 0 )
					begin
						if ( push_err_ea || pop_err_ea || ptr_err_ea )                                                                                                                                                                                          
							error_ea <= 1'b1;
					end		
			    else if ( err_mode == 1 )                                                                                                                                                                                            
					begin
						if  ( push_err_ea || pop_err_ea )
							error_ea <= 1'b1;
					end		
				else if ( err_mode == 2 )                                                                                                                                                                                            
					begin
						if ( push_err_ea || pop_err_ea )
							error_ea <= 1'b1;
						else
							error_ea <= 1'b0;
					end		
	        end                                                                                                                                                                                                                        
 	/**************************************************************
	* Implementation of data_in_width == data_out_width	ends here * 
	**************************************************************/
  
	/*****************************************************
	* Implementation of data_in_width < data_out_width	 * 
	*****************************************************/
	assign rd_addr_l = rst_mode ? rd_addr_ls : rd_addr_la;
	assign wr_addr_l = rst_mode ? wr_addr_ls : wr_addr_la;
	assign full_l = rst_mode ? full_ls : full_la; 
	assign half_full_l = rst_mode ? half_full_ls : half_full_la; 
	assign almost_full_l = rst_mode ? almost_full_ls : almost_full_la; 
	assign empty_l = rst_mode ? empty_ls : empty_la; 
	assign almost_empty_l = rst_mode ? almost_empty_ls : almost_empty_la; 
	assign we_n_l = rst_mode ? we_n_ls : we_n_la; 
	assign error_l = rst_mode ? error_ls : error_la; 
	assign ram_full_l = rst_mode ? ram_full_ls : ram_full_la; 
	assign part_wd_l = rst_mode ? part_wd_ls : part_wd_la; 
	assign cnt_l = rst_mode ? cnt_ls_r : cnt_la_r;
	assign data_out_l = rd_data;
	assign wr_data_l = rst_mode ? wr_data_ls : wr_data_la;

    /**************************************
	    Sync. reg implementation										
	***************************************/
   // Generate memory write enable and supply to memory	without flopping. 
   // Writes should only be allowed when the FIFO is not full so that 
   // overflow data is discarded. rd_en is used to control the advancement of 
   // rd_addr and only asserted when the memory is not empty.
   
   //Simultaneous push and pop is possible
   //part_wd = 0 indicates no data, hence don't write even if flush_n = 0
    assign we_n_ls =  ~((cnt_ls_r == k2 - 1) && !push_req_n && !ram_full_ls ) && ~( !push_req_n && !pop_req_n && ram_full_ls && (cnt_l == k2 - 1)) 
                      && ~(!flush_n && part_wd_ls && !ram_full_ls ) && ~( !flush_n && part_wd_ls && !pop_req_n && ram_full_ls );  //Removed checking for push_req_n in the last condition when ram_full --Nithin
    //When both pop_req_n and empty are LOW, enable read
	assign rd_en_ls = ~(pop_req_n || empty);
	
	//Collecting data
  // Last byte is not registered but we need to check if push_req_n is there --Nithin
    assign wr_data_ls =  byte_order ? wr_data1_ls : wr_data0_ls;  
	assign wr_data0_ls = flush_n ? ((cnt_ls_r == k2 - 1 & ~push_req_n) ? {data_hold0_ls_r, data_in} : {data_hold0_ls_r, {w1{1'b0}}}) : {data_hold0_ls_r, {data_in_width {1'b0}}};
	assign wr_data1_ls = flush_n ? ((cnt_ls_r == k2 - 1 & ~push_req_n ) ? {data_in, data_hold1_ls_r} : {{w1{1'b0}}, data_hold1_ls_r}) : {{data_in_width {1'b0}}, data_hold1_ls_r};
	
	//Keep track of sub-word writing
	always @(posedge clk) 
      if (!rst_n) 
		  cnt_ls_r <=  {`k2_bit_width{1'b0}};
	  else if ( !flush_n & part_wd_ls ) // Reset the counter if there is flush and also check if there is something to be written if there is no push_req 
		  cnt_ls_r <= {`k2_bit_width{1'b0}} + !push_req_n;  // If there is a push req, then push the data into the buffer, so load the counter with 1 --Nithin
      else if ( !push_req_n )
		  begin
			  if ( full_ls )	  
				  cnt_ls_r <= cnt_ls_r;
		      else if ( cnt_ls_r == k2 - 1 )
				  cnt_ls_r <=  {`k2_bit_width{1'b0}};
			  else  
				  cnt_ls_r <= cnt_ls_r + 1;
		  end
		  
	//Generating part_wd
	always @(posedge clk) 
      if (!rst_n) 
		  part_wd_ls <=  1'b0;
	  else if ( !flush_n && push_req_n && (!full_ls || (full_ls && ~pop_req_n)) ) // Deassert part_wd when flush and full and if there is a pop --Nithin
		  part_wd_ls <= 1'b0; 
      else if ( !push_req_n )
		  begin
		      if ( cnt_ls_r == k2 - 1 && (!full_ls || (full_ls && ~pop_req_n)) && flush_n )
				  part_wd_ls <=  1'b0;
			  else  
				  part_wd_ls <= 1;
		  end		  

	//Saving (k2 - 1) data input, byte_order = 0 ( First byte is in MSB position )	  
	always @(posedge clk)
		if ( !rst_n )
			data_hold0_ls_r <= 0;
        else if ( !we_n_l  )
			begin
				if ( flush_n )
				   data_hold0_ls_r <= 0;
				else
					begin
						if ( w1 < w2 )
							begin
								if ( k2 == 2)								
									data_hold0_ls_r <= data_in;
								else
									data_hold0_ls_r <= {data_in, {w2 - w1 - w1{1'b0}}};
							end		
					end		
			end	   
		else
			begin 
				if ( w1 < w2 ) // To avoid simulation STACK overflow, when w1 == w2
				case ( {flush_n, push_req_n})
					2'b00://save the data_in into current register position and flush the remaining regs.
					if ( k2 == 2 ) //only single sub-word to begin written to reg.
						begin
							if ( cnt_l == 0 ) 
								data_hold0_ls_r[data_in_width - 1 : 0] <= data_in;
						end
					else
						begin  	 
							//synthesis loop_limit 2000
							for ( i = 0; i < data_in_width; i = i + 1 )
								data_hold0_ls_r[ (k2 - 2 - cnt_l) * data_in_width + i] <= data_in[i];
						end	
					2'b01, 2'b11: data_hold0_ls_r <= data_hold0_ls_r;
					2'b10: 			
					if ( k2 == 2 )
						begin
							if ( cnt_l == 0 ) 
								data_hold0_ls_r[data_in_width - 1 : 0] <= data_in;
						end
					else
						begin		 
							//synthesis loop_limit 2000
							for ( i = 0; i < data_in_width; i = i + 1 )
								data_hold0_ls_r[ (k2 - 2 - cnt_l) * data_in_width + i] <= data_in[i];
						end		
		        endcase	
			end	

	//Saving (k2 - 1) data input, byte_order = 1 ( First byte is in LSB position )	  
	always @(posedge clk)
		if ( !rst_n )
			data_hold1_ls_r <= 0;
        else if ( !we_n_l  )
			begin
				if ( flush_n )
				   data_hold1_ls_r <= 0;
				else
					begin
						if ( w1 < w2 ) 
							begin
								if ( k2 == 2)
									data_hold1_ls_r <= data_in;
								else
									data_hold1_ls_r <= {{w2 - w1 - w1{1'b0}},data_in};
							end		
					end		
			end	   
		else
			begin
				if ( w1 < w2 ) // To avoid simulation STACK overflow, when w1 == w2
				case ( {flush_n, push_req_n})
					2'b00://save the data_in into current register position and flush the remaining regs.
					if ( k2 == 2 )
						begin
							if ( cnt_l == 0 ) 
								data_hold1_ls_r[data_in_width - 1 : 0] <= data_in;
						end
					else
						begin  
							//synthesis loop_limit 2000
							for ( i = 0; i < data_in_width; i = i + 1 )
								data_hold1_ls_r[ cnt_l * data_in_width + i] <= data_in[i];
						end	
					2'b01, 2'b11: data_hold1_ls_r <= data_hold1_ls_r;
					2'b10: 			
					if ( k2 == 2 )
						begin
							if ( cnt_l == 0 ) 
								data_hold1_ls_r[data_in_width - 1 : 0] <= data_in; //LHS,RHS widths are same
						end
					else
						begin 														 
							//synthesis loop_limit 2000
							for ( i = 0; i < data_in_width; i = i + 1 )
								data_hold1_ls_r[ cnt_l * data_in_width + i] <= data_in[i];
						end		
		        endcase	
			end	
				   
  // Increment the read address only when rd_en is in asserted. The if conditions are pretty
  // explanatory. 
  always @(posedge clk) 
      if (!rst_n) 
        rd_addr_ls <= {`_synp_bit_width{1'b0}};           	 
      else 
		  begin
			  if ( err_mode == 0 && !diag_n )
				  rd_addr_ls <= 0;
		      else 
				  case (rd_en_ls)  
					  1'b0: rd_addr_ls <= rd_addr_ls;
					  1'b1: if ( rd_addr_ls == depth - 1 )
						  rd_addr_ls <= {`_synp_bit_width{1'b0}};	 
					  else
						  rd_addr_ls <= rd_addr_ls + 1;
				  endcase
          end

   // Increment the write address only when wr_en is asserted. 
   always @(posedge clk) 
      if (!rst_n) 
        wr_addr_ls <= {`_synp_bit_width{1'b0}};           	 
      else 
		  begin
			  case (!we_n_ls)  
				  1'b0: wr_addr_ls <= wr_addr_ls;
				  1'b1: if ( wr_addr_ls == depth - 1 )
					  wr_addr_ls <= {`_synp_bit_width{1'b0}}; 
				  else
					  wr_addr_ls <= wr_addr_ls + 1;
			  endcase
           end
   
   // Increment or decrement the FIFO count on actual read and/or writes.
   always @(posedge clk) 
      if (!rst_n) 
        fifo_cnt_ls_r <= {(`_synp_bit_width+1){1'b0}};           	 
      else 
      	fifo_cnt_ls_r <= fifo_cnt_ls;
   
   //Combo block
   always @ ( we_n_ls or rd_en_ls or fifo_cnt_ls_r )
     case ({we_n_ls, rd_en_ls})  
	   2'b10: fifo_cnt_ls = fifo_cnt_ls_r;
	   2'b00: fifo_cnt_ls = fifo_cnt_ls_r + 1;	 
	   2'b11: fifo_cnt_ls = fifo_cnt_ls_r - 1;	 
	   2'b01: fifo_cnt_ls = fifo_cnt_ls_r;
	 endcase

   // Generate the empty signal based on whether a write and/or read is being allowed
   // and the current state of fifo_cnt. The if conditions are pretty explanatory.
   always @(posedge clk) 
      if (!rst_n) 
        empty_ls <= 1'b1;           	 
      else
		  begin
			  if(empty_ls & !we_n_ls) 
				  empty_ls <= 1'b0;
			  else if((fifo_cnt_ls_r == `EMPTY_COUNT_P1) & rd_en_ls & we_n_ls ) 
				  empty_ls <= 1'b1;	 
			  else if(fifo_cnt_ls_r == `EMPTY_COUNT ) 
				  empty_ls <= 1'b1;	 
			  else 
				  empty_ls <= 1'b0;
		  end	  

   // Generate the ram_full signal based on whether a write and/or read is being allowed
   // and the current state of fifo_cnt. The if conditions are pretty explanatory.
	  always @(posedge clk) 
      if (!rst_n) 
        ram_full_ls <= 1'b0;           	 
      else 
	  begin
         if(ram_full_ls & rd_en_ls & we_n_ls) // w1 < w2 & we_n_ls) 
	        ram_full_ls <= 1'b0;
	     else if((fifo_cnt_ls_r == `FULL_COUNT_1) & !rd_en_ls & !we_n_ls) 
	        ram_full_ls <= 1'b1;	 
	     else if(fifo_cnt_ls_r == `FULL_COUNT) 
	        ram_full_ls <= 1'b1;	 
	     else 
	        ram_full_ls <= 1'b0;	 
      end
   	  
	  //FIFO full = ram_full && buffer_full
	  always @(posedge clk) 
      if (!rst_n) 
        full_ls <= 1'b0;           	 
      else 
	  begin
		  if ( k2 == 2 )
			  begin
				  if  ( !pop_req_n )
					  full_ls <= 1'b0;
				  else if ((ram_full_ls && cnt_ls_r == 0 && !push_req_n ) || (fifo_cnt_ls_r == `FULL_COUNT_1 & !rd_en_ls & !we_n_ls & !flush_n ) ||(fifo_cnt_ls_r == `FULL_COUNT & !flush_n ))
					  full_ls <= 1;										
			  end
		   else
			  begin
				   if  ( !pop_req_n )
					  full_ls <= 1'b0;
				  else if (( ram_full_ls && cnt_ls_r == (k2 - 2) && !push_req_n ) ||(ram_full_ls & !flush_n )) 
					  full_ls <= 1;
			  end
		end	  
	  
	  //Generation of almost_empty flag
	  always @(posedge clk) 
      if (!rst_n) 
        almost_empty_ls <= 1'b1;           	 
      else
		  begin
			  if ( fifo_cnt_ls <= ae_level	)
				  almost_empty_ls <= 1'b1;
			  else
				  almost_empty_ls <= 1'b0;
		  end	
		  
	  //Generation of half_full flag
	  always @(posedge clk) 
      if (!rst_n) 
        half_full_ls <= 1'b0;           	 
      else 
	  begin
		  if ( fifo_cnt_ls >= (depth + 1)/2 )
			  half_full_ls <= 1'b1;
		  else
			  half_full_ls <= 1'b0;
	  end	
				  
	  //Generation of almost_full flag
	  always @(posedge clk) 
      if (!rst_n) 
        almost_full_ls <= 1'b0;           	 
      else 
	  begin
		  if ( fifo_cnt_ls >= af_thresh )
			  almost_full_ls <= 1'b1;
		  else
			  almost_full_ls <= 1'b0;
	  end	
	  
	  //Error setting based on 
	  //1. Push error: Attempting to write a FIFO when it is FULL ( overflow condition)
	  //2. Pop  error: Attemping to drain the FIFO when it is empty ( underflow condition )
	  //3. Pointer error: wr_addr and rd_addr pointing to different mem. locations when FIFO
	  //                  is either Empty of Full
			assign push_err_ls = (!push_req_n && full_ls && pop_req_n) || ( !flush_n && ram_full_ls && pop_req_n);
			assign pop_err_ls = !pop_req_n && empty_ls;
			assign ptr_err_ls = (empty_ls &&(rd_addr_ls != wr_addr_ls))|| (ram_full_ls && (rd_addr_ls != wr_addr_ls)) || ((rd_addr_ls == wr_addr_ls)&&(~(ram_full_ls || empty_ls)));

		//Registering the Error
		always @(posedge clk )                                                                                                                                                                                                     
		if( !rst_n  )
			error_ls <= 0;                                                                                                                                                                                                         
		else
			begin
				if( err_mode == 0 )
					begin
						if ( push_err_ls || pop_err_ls || ptr_err_ls )                                                                                                                                                                                          
							error_ls <= 1'b1;
					end		
			    else if ( err_mode == 1 )                                                                                                                                                                                            
					begin
						if  ( push_err_ls || pop_err_ls )
							error_ls <= 1'b1;
					end		
				else if ( err_mode == 2 )                                                                                                                                                                                            
					begin
						if ( push_err_ls || pop_err_ls )
							error_ls <= 1'b1;
						else
							error_ls <= 1'b0;
					end		
	        end                                                                                                                                                                                                                        

			
    /**************************************
	    Async. reg implementation										
	***************************************/   
	//Simultaneous push and pop is possible
    assign we_n_la =  ~((cnt_la_r == k2 - 1) && !push_req_n && !ram_full_la ) && ~( !push_req_n && !pop_req_n && ram_full_la && (cnt_l == k2 - 1)) 
                      && ~(!flush_n && part_wd_la && !ram_full_la ) && ~( !flush_n && part_wd_la && !pop_req_n && ram_full_la ); //Removed checking for push_req_n in the last condition when ram_full --Nithin

    //When both pop_req_n and empty are LOW, enable read
	assign rd_en_la = ~(pop_req_n || empty);

	//Collecting data
  // Last byte is not registered but we need to check if push_req_n is there --Nithin
    assign wr_data_la =  byte_order ? wr_data1_la : wr_data0_la;  
	assign wr_data0_la = flush_n ? ((cnt_la_r == k2 - 1 & ~push_req_n) ? {data_hold0_la_r, data_in} : {data_hold0_la_r, {w1{1'b0}}}) : {data_hold0_la_r, {data_in_width {1'b0}}};
	assign wr_data1_la = flush_n ? ((cnt_la_r == k2 - 1 & ~push_req_n) ? {data_in, data_hold1_la_r} : {{w1{1'b0}}, data_hold1_la_r}) : {{data_in_width {1'b0}}, data_hold1_la_r};

	//Keep track of sub-word writing
	always @(posedge clk or negedge rst_n) 
      if (!rst_n) 
		  cnt_la_r <=  {`k2_bit_width{1'b0}};           	 
	  else if ( !flush_n & part_wd_la) 		// Reset the counter if there is flush and also check if there is something to be written and there is no push_req
		  cnt_la_r <= {`k2_bit_width{1'b0}} + !push_req_n; // If there is a push_req push the data into the buffer so load the counter with 1 --Nithin
      else if ( !push_req_n )
		  begin
			  if ( full_la && we_n_l )
				  cnt_la_r <= cnt_la_r;
			  else if ( cnt_la_r == k2 - 1 )
				  cnt_la_r <=  {`k2_bit_width{1'b0}};
			  else  
				  cnt_la_r <= cnt_la_r + 1;
		  end		  
				
	//Generating part_wd
	always @(posedge clk or negedge rst_n) 
      if (!rst_n) 
		  part_wd_la <=  1'b0;
	  else if ( !flush_n && push_req_n && (!full_la || (full_la && ~pop_req_n)))  // Deassert part_wd when flush and full and if there is a pop --Nithin
		  part_wd_la <= 1'b0; 
      else if ( !push_req_n )
		  begin
		      if ( cnt_la_r == k2 - 1 && (!full_la || (full_la && ~pop_req_n)) && flush_n )//added flush_n condn. 20/7/05
				  part_wd_la <=  1'b0;
			  else  
				  part_wd_la <= 1;
		  end		  
		  
	//Saving (k2 - 1) data input, byte_order = 0 ( First byte is in MSB position )	  
	always @(posedge clk or negedge rst_n)
		if ( !rst_n )
			data_hold0_la_r <= 0;
        else if ( !we_n_l  )
			begin
				if ( flush_n )
				   data_hold0_la_r <= 0;
				else
					begin
						if ( w1 < w2 ) 
							begin
								if ( k2 == 2)
									data_hold0_la_r <= data_in;
								else
									data_hold0_la_r <= {data_in,{w2 - w1 - w1{1'b0}}};
							end		
					end		
			end	   
		else
			begin
				if ( w1 < w2 ) // To avoid simulation STACK overflow, when w1 == w2
				case ( {flush_n, push_req_n})
					2'b00://save the data_in into current register position and flush the remaining regs.
					if ( k2 == 2 ) //only single sub-word to begin written to reg.
						begin
							if ( cnt_l == 0 ) 
								data_hold0_la_r[data_in_width - 1 : 0] <= data_in;
						end
					else
						begin										  
							//synthesis loop_limit 2000
							for ( i = 0; i <  data_in_width; i = i + 1 )
								data_hold0_la_r[ (k2 - 2 - cnt_l) * data_in_width + i] <= data_in[i];
						end	
					2'b01, 2'b11: data_hold0_la_r <= data_hold0_la_r;
					2'b10: 			
					if ( k2 == 2 )
						begin
							if ( cnt_l == 0 ) 
								data_hold0_la_r[data_in_width - 1 : 0] <= data_in;
						end
					else
						begin						   
							//synthesis loop_limit 2000
							for ( i = 0; i < data_in_width; i = i + 1 )
								data_hold0_la_r[ (k2 - 2 - cnt_l) * data_in_width + i] <= data_in[i];
						end		
		        endcase	
			end	

	//Saving (k2 - 1) data input, byte_order = 1 ( First byte is in LSB position )	  
	always @(posedge clk or negedge rst_n)
		if ( !rst_n )
			data_hold1_la_r <= 0;
        else if ( !we_n_l  )
			begin
				if ( flush_n )
				   data_hold1_la_r <= 0;
				else
					begin
						if ( w1 < w2 ) 
							begin
								if ( k2 == 2)
									data_hold1_la_r <= data_in;
								else
									data_hold1_la_r <= {{w2 - w1 - w1{1'b0}},data_in};
							end		
					end		
			end	   
		else
			begin
				if ( w1 < w2 ) // To avoid simulation STACK overflow, when w1 == w2
				case ( {flush_n, push_req_n})
					2'b00://save the data_in into current register position and flush the remaining regs.
					if ( k2 == 2 )
						begin
							if ( cnt_l == 0 ) 
								data_hold1_la_r[data_in_width - 1 : 0] <= data_in;
						end
					else
						begin											 
							//synthesis loop_limit 2000
							for ( i = 0; i < data_in_width; i = i + 1 )
								data_hold1_la_r[ cnt_l * data_in_width + i] <= data_in[i];
						end	
					2'b01, 2'b11: data_hold1_la_r <= data_hold1_la_r;
					2'b10: 			
					if ( k2 == 2 )
						begin
							if ( cnt_l == 0 ) 
								data_hold1_la_r[data_in_width - 1 : 0] <= data_in;
						end
					else
						begin 										  
							//synthesis loop_limit 2000
							for ( i = 0; i < data_in_width; i = i + 1 )
								data_hold1_la_r[ cnt_l * data_in_width + i] <= data_in[i];
						end		
		        endcase	
			end	
  
  // Increment the read address only when rd_en is in asserted. The if conditions are pretty
  // explanatory. 
  always @(posedge clk or negedge rst_n) 
      if (!rst_n) 
        rd_addr_la <= {`_synp_bit_width{1'b0}};           	 
      else 
		  begin
			  if ( err_mode == 0 && !diag_n )
				  rd_addr_la <= 0;
		      else 
				  case (rd_en_la)  
					  1'b0: rd_addr_la <= rd_addr_la;
					  1'b1: if ( rd_addr_la == depth - 1 )
						  rd_addr_la <= {`_synp_bit_width{1'b0}};	 
					  else
						  rd_addr_la <= rd_addr_la + 1;
				  endcase
          end

   // Increment the write address only when wr_en is asserted. 
   always @(posedge clk or negedge rst_n) 
      if (!rst_n) 
        wr_addr_la <= {`_synp_bit_width{1'b0}};           	 
      else 
		  begin
			  case (!we_n_la)  
				  1'b0: wr_addr_la <= wr_addr_la;
				  1'b1: if ( wr_addr_la == depth - 1 )
					  wr_addr_la <= {`_synp_bit_width{1'b0}}; 
				  else
					  wr_addr_la <= wr_addr_la + 1;
			  endcase
           end
   
   // Increment or decrement the FIFO count on actual read and/or writes.
   always @(posedge clk or negedge rst_n) 
      if (!rst_n) 
        fifo_cnt_la_r <= {(`_synp_bit_width+1){1'b0}};           	 
      else 
      	fifo_cnt_la_r <= fifo_cnt_la;
   
   //Combo block
   always @ ( we_n_la or rd_en_la or fifo_cnt_la_r )
     case ({we_n_la, rd_en_la})  
	   2'b10: fifo_cnt_la = fifo_cnt_la_r;
	   2'b00: fifo_cnt_la = fifo_cnt_la_r + 1;	 
	   2'b11: fifo_cnt_la = fifo_cnt_la_r - 1;	 
	   2'b01: fifo_cnt_la = fifo_cnt_la_r;
	 endcase

   // Generate the empty signal based on whether a write and/or read is being allowed
   // and the current state of fifo_cnt. The if conditions are pretty explanatory.
   always @(posedge clk or negedge rst_n) 
      if (!rst_n) 
        empty_la <= 1'b1;           	 
      else
		  begin
			  if(empty_la & !we_n_la) 
				  empty_la <= 1'b0;
			  else if((fifo_cnt_la_r == `EMPTY_COUNT_P1) & rd_en_la & we_n_la ) 
				  empty_la <= 1'b1;	 
			  else if(fifo_cnt_la_r == `EMPTY_COUNT ) 
				  empty_la <= 1'b1;	 
			  else 
				  empty_la <= 1'b0;
		  end	  

   // Generate the ram_full signal based on whether a write and/or read is being allowed
   // and the current state of fifo_cnt. The if conditions are pretty explanatory.
	  always @(posedge clk or negedge rst_n) 
      if (!rst_n) 
        ram_full_la <= 1'b0;           	 
      else 
	  begin
         if (ram_full_la & rd_en_la & we_n_la) 
	        ram_full_la <= 1'b0;
	     else if ((fifo_cnt_la_r == `FULL_COUNT_1) & !rd_en_la & !we_n_la) 
	        ram_full_la <= 1'b1;	 
	     else if (fifo_cnt_la_r == `FULL_COUNT) 
	        ram_full_la <= 1'b1;	 
	     else 
	        ram_full_la <= 1'b0;	 
      end
   	  
	  //FIFO full = ram_full && buffer_full
	  always @(posedge clk or negedge rst_n) 
      if (!rst_n) 
        full_la <= 1'b0;           	 
      else 
	  begin
		  if ( k2 == 2 )
			  begin
				  if  ( !pop_req_n )
					  full_la <= 1'b0;
				  else if (( ram_full_la && cnt_la_r == 0 && !push_req_n )  || (fifo_cnt_la_r == `FULL_COUNT_1 & !rd_en_la & !we_n_la & !flush_n ) ||(fifo_cnt_la_r == `FULL_COUNT & !flush_n ))
					  full_la <= 1;										 
			  end
		   else
			  begin
				   if  ( !pop_req_n )
					  full_la <= 1'b0;
				  else if (( ram_full_la && cnt_la_r == (k2 - 2) && !push_req_n ) ||(ram_full_la & !flush_n )) 
					  full_la <= 1;
			  end
		end	  					  
				  	  				  	  
	  //Generation of almost_empty flag
	  always @(posedge clk or negedge rst_n) 
      if (!rst_n) 
        almost_empty_la <= 1'b1;           	 
      else
		  begin
			  if ( fifo_cnt_la <= ae_level	)
				  almost_empty_la <= 1'b1;
			  else
				  almost_empty_la <= 1'b0;
		  end	
		  
	  //Generation of half_full flag
	  always @(posedge clk or negedge rst_n) 
      if (!rst_n) 
        half_full_la <= 1'b0;           	 
      else 
	  begin
		  if ( fifo_cnt_la >= (depth + 1)/2 )
			  half_full_la <= 1'b1;
		  else
			  half_full_la <= 1'b0;
	  end	
				  
	  //Generation of almost_full flag
	  always @(posedge clk or negedge rst_n) 
      if (!rst_n) 
        almost_full_la <= 1'b0;           	 
      else 
	  begin
		  if ( fifo_cnt_la >= af_thresh )
			  almost_full_la <= 1'b1;
		  else
			  almost_full_la <= 1'b0;
	  end	
	  
	  //Error setting based on 
	  //1. Push error: Attempting to write a FIFO when it is FULL ( overflow condition)
	  //2. Pop  error: Attemping to drain the FIFO when it is empty ( underflow condition )
	  //3. Pointer error: wr_addr and rd_addr pointing to different mem. locations when FIFO
	  //                  is either Empty of Full
			assign push_err_la = (!push_req_n && full_la && pop_req_n) || ( !flush_n && ram_full_la && pop_req_n);
			assign pop_err_la = !pop_req_n && empty_la;
			assign ptr_err_la = (empty_la &&(rd_addr_la != wr_addr_la))|| (ram_full_la && (rd_addr_la != wr_addr_la)) || ((rd_addr_la == wr_addr_la)&&(~(ram_full_la || empty_la)));

		//Registering the Error
		always @(posedge clk or negedge rst_n )                                                                                                                                                                                                     
		if( !rst_n  )
			error_la <= 0;                                                                                                                                                                                                         
		else
			begin
				if( err_mode == 0 )
					begin
						if ( push_err_la || pop_err_la || ptr_err_la )                                                                                                                                                                                          
							error_la <= 1'b1;
					end		
			    else if ( err_mode == 1 )                                                                                                                                                                                            
					begin
						if  ( push_err_la || pop_err_la )
							error_la <= 1'b1;
					end		
				else if ( err_mode == 2 )                                                                                                                                                                                            
					begin
						if ( push_err_la || pop_err_la )
							error_la <= 1'b1;
						else
							error_la <= 1'b0;
					end		
	        end                                                                                                                                                                                                                        
   
	
  	/**************************************************************
	* Implementation of data_in_width < data_out_width	ends here * 
	**************************************************************/
	
	/*****************************************************
	* Implementation of data_in_width > data_out_width	 * 
	*****************************************************/
	assign rd_addr_g = rst_mode ? rd_addr_gs : rd_addr_ga;
	assign wr_addr_g = rst_mode ? wr_addr_gs : wr_addr_ga;
	assign full_g = rst_mode ? full_gs : full_ga; 
	assign half_full_g = rst_mode ? half_full_gs : half_full_ga; 
	assign almost_full_g = rst_mode ? almost_full_gs : almost_full_ga; 
	assign empty_g = rst_mode ? empty_gs : empty_ga; 
	assign almost_empty_g = rst_mode ? almost_empty_gs : almost_empty_ga; 
	assign we_n_g = rst_mode ? we_n_gs : we_n_ga; 
	assign error_g = rst_mode ? error_gs : error_ga; 
	assign data_out_g = rst_mode ? data_out_gs : data_out_ga;
    assign wr_data_g = data_in;
	
    /**************************************
	    Sync. reg implementation										
	***************************************/
   // Generate memory write enable and supply to memory	without flopping. 
   // Writes should only be allowed when the FIFO is not full so that 
   // overflow data is discarded. rd_en is used to control the advancement of 
   // rd_addr and only asserted when the memory is not empty.
   //Simultaneous read & write is possible under FULL condition, iff
   //pop_req_n = 0  and there is only one sub-word to begin read.
   //See the last condition: !push_req_n && !pop_req_n && cnt_gs_r == (k1 - 1) && full_gs	   
    assign we_n_gs = push_req_n || full && ~( !push_req_n && !pop_req_n && cnt_gs_r == (k1 - 1) && full_gs );	//Enable read only when last sub-word is sent out of FIFO and there is pop request & FIFO is not empty 
	assign rd_en_gs = (cnt_gs_r == k1 - 1) && !pop_req_n && !empty;
	//Output selection based on byte order
	assign data_out_gs = byte_order ? data_out_gs1 : data_out_gs0;
	
	//Output MUX implementation	- byte order = 0
	always @ (rd_data or cnt_gs_r)                          
	begin                                        
	    data_out_gs0 = 0;  
		//synthesis loop_limit 2000
		for ( i = 0; i < w2 ; i = i + 1 ) 
		   data_out_gs0[i] = rd_data[( k1 - 1 - cnt_gs_r ) * w2 + i ];     
	end                                          

	//Output MUX implementation	- byte order = 1
	always @ (rd_data or cnt_gs_r)                          
	begin                                        
	    data_out_gs1 = 0;             
		//synthesis loop_limit 2000
		for ( i = 0; i < w2 ; i = i + 1 ) 
		   data_out_gs1[i] = rd_data[ cnt_gs_r * w2 + i ];     
	end                                          

	//Keep track of sub-word popping
	always @(posedge clk) 
      if (!rst_n) 
		  cnt_gs_r <=  {`k1_bit_width{1'b0}};
      else if ( !pop_req_n )
		  begin
			  if ( empty_gs )
				  cnt_gs_r <= cnt_gs_r;
		      else if ( cnt_gs_r == k1 - 1 )
				  cnt_gs_r <=  {`k1_bit_width{1'b0}};
			  else  
				  cnt_gs_r <= cnt_gs_r + 1;
		  end		  
  // Increment the read address only when rd_en is in asserted. The if conditions are pretty
  // explanatory. 
  always @(posedge clk) 
      if (!rst_n) 
        rd_addr_gs <= {`_synp_bit_width{1'b0}};           	 
      else 
		  begin
			  if ( err_mode == 0 && !diag_n )
				  rd_addr_gs <= 0;
		      else 
				  case (rd_en_gs)  
					  1'b0: rd_addr_gs <= rd_addr_gs;
					  1'b1: if ( rd_addr_gs == depth - 1 )
						  rd_addr_gs <= 0;	 
					  else
						  rd_addr_gs <= rd_addr_gs + 1;
				  endcase
          end

   // Increment the write address only when wr_en is asserted. 
   always @(posedge clk) 
      if (!rst_n) 
        wr_addr_gs <= {`_synp_bit_width{1'b0}};           	 
      else 
		  begin
			  case (!we_n_gs)  
				  1'b0: wr_addr_gs <= wr_addr_gs;
				  1'b1: if ( wr_addr_gs == depth - 1 )
					  wr_addr_gs <= 0; 
				  else
					  wr_addr_gs <= wr_addr_gs + 1;
			  endcase
           end
   
   // Increment or decrement the FIFO count on actual read and/or writes.
   always @(posedge clk) 
      if (!rst_n) 
        fifo_cnt_gs_r <= {(`_synp_bit_width+1){1'b0}};           	 
      else 
      	fifo_cnt_gs_r <= fifo_cnt_gs;
   
   //Combo block
   always @ ( we_n_gs or rd_en_gs or fifo_cnt_gs_r )
     case ({we_n_gs, rd_en_gs})  
	   2'b10: fifo_cnt_gs = fifo_cnt_gs_r;
	   2'b00: fifo_cnt_gs = fifo_cnt_gs_r + 1;	 
	   2'b11: fifo_cnt_gs = fifo_cnt_gs_r - 1;	 
	   2'b01: fifo_cnt_gs = fifo_cnt_gs_r;
	 endcase

   // Generate the empty signal based on whether a write and/or read is being allowed
   // and the current state of fifo_cnt. The if conditions are pretty explanatory.
   always @(posedge clk) 
      if (!rst_n) 
        empty_gs <= 1'b1;           	 
      else
		  begin
			  if(empty_gs & !we_n_gs) 
				  empty_gs <= 1'b0;
			  else if((fifo_cnt_gs_r == `EMPTY_COUNT_P1) & rd_en_gs & we_n_gs ) 
				  empty_gs <= 1'b1;	 
			  else if(fifo_cnt_gs_r == `EMPTY_COUNT ) 
				  empty_gs <= 1'b1;	 
			  else 
				  empty_gs <= 1'b0;
		  end	  

   // Generate the full signal based on whether a write and/or read is being allowed
   // and the current state of fifo_cnt. The if conditions are pretty explanatory.
	  always @(posedge clk) 
      if (!rst_n) 
        full_gs <= 1'b0;           	 
      else 
	  begin
         if(full_gs & rd_en_gs & we_n_gs) 
	        full_gs <= 1'b0;
	     else if((fifo_cnt_gs_r == `FULL_COUNT_1) & !rd_en_gs & !we_n_gs) 
	        full_gs <= 1'b1;	 
	     else if(fifo_cnt_gs_r == `FULL_COUNT) 
	        full_gs <= 1'b1;	 
	     else 
	        full_gs <= 1'b0;	 
      end
   	  
	  //Generation of almost_empty flag
	  always @(posedge clk) 
      if (!rst_n) 
        almost_empty_gs <= 1'b1;           	 
      else
		  begin
			  if ( fifo_cnt_gs <= ae_level	)
				  almost_empty_gs <= 1'b1;
			  else
				  almost_empty_gs <= 1'b0;
		  end	
		  
	  //Generation of half_full flag
	  always @(posedge clk) 
      if (!rst_n) 
        half_full_gs <= 1'b0;           	 
      else 
	  begin
		  if ( fifo_cnt_gs >= (depth + 1)/2 )
			  half_full_gs <= 1'b1;
		  else
			  half_full_gs <= 1'b0;
	  end	
				  
	  //Generation of almost_full flag
	  always @(posedge clk) 
      if (!rst_n) 
        almost_full_gs <= 1'b0;           	 
      else 
	  begin
		  if ( fifo_cnt_gs >= af_thresh )
			  almost_full_gs <= 1'b1;
		  else
			  almost_full_gs <= 1'b0;
	  end	
	  
	  //Error setting based on 
	  //1. Push error: Attempting to write a FIFO when it is FULL ( overflow condition)
	  //2. Pop  error: Attemping to drain the FIFO when it is empty ( underflow condition )
	  //3. Pointer error: wr_addr and rd_addr pointing to different mem. locations when FIFO
	  //                  is either Empty of Full
			assign push_err_gs = !push_req_n && full_gs && ( pop_req_n || (!pop_req_n && cnt_gs_r != k1 - 1));
			assign pop_err_gs = !pop_req_n && empty_gs;
			assign ptr_err_gs = (empty_gs &&(rd_addr_gs != wr_addr_gs))|| (full_gs && (rd_addr_gs != wr_addr_gs)) || ((rd_addr_gs == wr_addr_gs)&&(~(full_gs || empty_gs)));

		//Registering the Error
		always @(posedge clk )                                                                                                                                                                                                     
		if( !rst_n  )
			error_gs <= 0;                                                                                                                                                                                                         
		else
			begin
				if( err_mode == 0 )
					begin
						if ( push_err_gs || pop_err_gs || ptr_err_gs )                                                                                                                                                                                          
							error_gs <= 1'b1;
					end		
			    else if ( err_mode == 1 )                                                                                                                                                                                            
					begin
						if  ( push_err_gs || pop_err_gs )
							error_gs <= 1'b1;
					end		
				else if ( err_mode == 2 )                                                                                                                                                                                            
					begin
						if ( push_err_gs || pop_err_gs )
							error_gs <= 1'b1;
						else
							error_gs <= 1'b0;
					end		
	        end                                                                                                                                                                                                                        
	
	
	
    /**************************************
	    Async. reg implementation										
	***************************************/
   // Generate memory write enable and supply to memory	without flopping. 
   // Writes should only be allowed when the FIFO is not full so that 
   // overflow data is discarded. rd_en is used to control the advancement of 
   // rd_addr and only asserted when the memory is not empty.
   //Simultaneous read & write is possible under FULL condition, iff
   //pop_req_n = 0  and there is only one sub-word to begin read.
   //See the last condition: !push_req_n && !pop_req_n && cnt_ga_r == (k1 - 1) && full_ga	   
    assign we_n_ga = push_req_n || full && ~( !push_req_n && !pop_req_n && cnt_ga_r == (k1 - 1) && full_ga );
	//Enable read only when last sub-word is sent out of FIFO and there is pop request & FIFO is not empty 
	assign rd_en_ga = (cnt_ga_r == k1 - 1) && !pop_req_n && !empty;
	//Output selection based on byte order
	assign data_out_ga = byte_order ? data_out_ga1 : data_out_ga0;

	//Output MUX implementation	- byte order = 0
	always @ (rd_data or cnt_ga_r)                          
	begin                                        
	    data_out_ga0 = 0;            
		//synthesis loop_limit 2000
		for ( i = 0; i < w2 ; i = i + 1 ) 
		   data_out_ga0[i] = rd_data[( k1 - 1 - cnt_ga_r ) * w2 + i ];     
	end                                          

	//Output MUX implementation	- byte order = 1
	always @ (rd_data or cnt_ga_r)                          
	begin                                        
	    data_out_ga1 = 0;                 
		//synthesis loop_limit 2000
		for ( i = 0; i < w2 ; i = i + 1 ) 
		   data_out_ga1[i] = rd_data[ cnt_ga_r  * w2 + i ];     
	end                                          

	//Keep track of sub-word popping
	always @(posedge clk or negedge rst_n) 
      if (!rst_n) 
		  cnt_ga_r <=  {`k1_bit_width{1'b0}};
      else if ( !pop_req_n )
		  begin
			  if ( empty_ga )
				  cnt_ga_r <= cnt_ga_r;
		      else if ( cnt_ga_r == k1 - 1 )
				  cnt_ga_r <=  {`k1_bit_width{1'b0}};
			  else  
				  cnt_ga_r <= cnt_ga_r + 1;
		  end		  
  // Increment the read address only when rd_en is in asserted. The if conditions are pretty
  // explanatory. 
  always @(posedge clk or negedge rst_n) 
      if (!rst_n) 
        rd_addr_ga <= {`_synp_bit_width{1'b0}};           	 
      else 
		  begin
			  if ( err_mode == 0 && !diag_n )
				  rd_addr_ga <= 0;
		      else 
				  case (rd_en_ga)  
					  1'b0: rd_addr_ga <= rd_addr_ga;
					  1'b1: if ( rd_addr_ga == depth - 1 )
						  rd_addr_ga <= 0;	 
					  else
						  rd_addr_ga <= rd_addr_ga + 1;
				  endcase
          end

   // Increment the write address only when wr_en is asserted. 
   always @(posedge clk or negedge rst_n) 
      if (!rst_n) 
        wr_addr_ga <= {`_synp_bit_width{1'b0}};           	 
      else 
		  begin
			  case (!we_n_ga)  
				  1'b0: wr_addr_ga <= wr_addr_ga;
				  1'b1: if ( wr_addr_ga == depth - 1 )
					  wr_addr_ga <= 0; 
				  else
					  wr_addr_ga <= wr_addr_ga + 1;
			  endcase
           end
   
   // Increment or decrement the FIFO count on actual read and/or writes.
   always @(posedge clk or negedge rst_n) 
      if (!rst_n) 
        fifo_cnt_ga_r <= {(`_synp_bit_width+1){1'b0}};           	 
      else 
      	fifo_cnt_ga_r <= fifo_cnt_ga;
   
   //Combo block
   always @ ( we_n_ga or rd_en_ga or fifo_cnt_ga_r )
     case ({we_n_ga, rd_en_ga})  
	   2'b10: fifo_cnt_ga = fifo_cnt_ga_r;
	   2'b00: fifo_cnt_ga = fifo_cnt_ga_r + 1;	 
	   2'b11: fifo_cnt_ga = fifo_cnt_ga_r - 1;	 
	   2'b01: fifo_cnt_ga = fifo_cnt_ga_r;
	 endcase

   // Generate the empty signal based on whether a write and/or read is being allowed
   // and the current state of fifo_cnt. The if conditions are pretty explanatory.
   always @(posedge clk or negedge rst_n) 
      if (!rst_n) 
        empty_ga <= 1'b1;           	 
      else
		  begin
			  if(empty_ga & !we_n_ga) 
				  empty_ga <= 1'b0;
			  else if((fifo_cnt_ga_r == `EMPTY_COUNT_P1) & rd_en_ga & we_n_ga ) 
				  empty_ga <= 1'b1;	 
			  else if(fifo_cnt_ga_r == `EMPTY_COUNT ) 
				  empty_ga <= 1'b1;	 
			  else 
				  empty_ga <= 1'b0;
		  end	  

   // Generate the full signal based on whether a write and/or read is being allowed
   // and the current state of fifo_cnt. The if conditions are pretty explanatory.
	  always @(posedge clk or negedge rst_n) 
      if (!rst_n) 
        full_ga <= 1'b0;           	 
      else 
	  begin
         if(full_ga & rd_en_ga & we_n_ga) 
	        full_ga <= 1'b0;
	     else if((fifo_cnt_ga_r == `FULL_COUNT_1) & !rd_en_ga & !we_n_ga) 
	        full_ga <= 1'b1;	 
	     else if(fifo_cnt_ga_r == `FULL_COUNT) 
	        full_ga <= 1'b1;	 
	     else 
	        full_ga <= 1'b0;	 
      end
   	  
	  //Generation of almost_empty flag
	  always @(posedge clk or negedge rst_n) 
      if (!rst_n) 
        almost_empty_ga <= 1'b1;           	 
      else
		  begin
			  if ( fifo_cnt_ga <= ae_level	)
				  almost_empty_ga <= 1'b1;
			  else
				  almost_empty_ga <= 1'b0;
		  end	
		  
	  //Generation of half_full flag
	  always @(posedge clk or negedge rst_n) 
      if (!rst_n) 
        half_full_ga <= 1'b0;           	 
      else 
	  begin
		  if ( fifo_cnt_ga >= (depth + 1)/2 )
			  half_full_ga <= 1'b1;
		  else
			  half_full_ga <= 1'b0;
	  end	
				  
	  //Generation of almost_full flag
	  always @(posedge clk or negedge rst_n) 
      if (!rst_n) 
        almost_full_ga <= 1'b0;           	 
      else 
	  begin
		  if ( fifo_cnt_ga >= af_thresh )
			  almost_full_ga <= 1'b1;
		  else
			  almost_full_ga <= 1'b0;
	  end	
	  
	  //Error setting based on 
	  //1. Push error: Attempting to write a FIFO when it is FULL ( overflow condition)
	  //2. Pop  error: Attemping to drain the FIFO when it is empty ( underflow condition )
	  //3. Pointer error: wr_addr and rd_addr pointing to different mem. locations when FIFO
	  //                  is either Empty of Full
			assign push_err_ga = !push_req_n && full_ga && ( pop_req_n || (!pop_req_n && cnt_ga_r != k1 - 1));
			assign pop_err_ga = !pop_req_n && empty_ga;
			assign ptr_err_ga = (empty_ga &&(rd_addr_ga != wr_addr_ga))|| (full_ga && (rd_addr_ga != wr_addr_ga)) || ((rd_addr_ga == wr_addr_ga)&&(~(full_ga || empty_ga)));

		//Registering the Error
		always @(posedge clk or negedge rst_n )                                                                                                                                                                                                     
		if( !rst_n  )
			error_ga <= 0;                                                                                                                                                                                                         
		else
			begin
				if( err_mode == 0 )
					begin
						if ( push_err_ga || pop_err_ga || ptr_err_ga )                                                                                                                                                                                          
							error_ga <= 1'b1;
					end		
			    else if ( err_mode == 1 )                                                                                                                                                                                            
					begin
						if  ( push_err_ga || pop_err_ga )
							error_ga <= 1'b1;
					end		
				else if ( err_mode == 2 )                                                                                                                                                                                            
					begin
						if ( push_err_ga || pop_err_ga )
							error_ga <= 1'b1;
						else
							error_ga <= 1'b0;
					end		
	        end                                                                                                                                                                                                                        
	
 	/**************************************************************
	* Implementation of data_in_width > data_out_width	ends here * 
	**************************************************************/
			
`undef k1_bit_width
`undef K12BITS
`undef POS00
`undef k2_bit_width
`undef K22BITS
`undef POS0
`undef FULL_COUNT_1
`undef EMPTY_COUNT_P1
`undef FULL_COUNT
`undef EMPTY_COUNT
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
