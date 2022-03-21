
//--------------------------------------------------------------------------------------------------
//
// Title       : asymfifoctl_s2_sf_bin.v
// Design      : examples
//-------------------------------------------------------------------------------------------------
// Description : DW_asymfifoctl_s2_sf is an asymmetric I/O dual independent clock FIFO RAM controller. 
// It is designed to interface with a dual-port synchronous RAM.
// The input data bit width of DW_asymfifoctl_s2_sf can be different than its output data bit width, 
// but must have an integer-multiple relationship (the input bit width being a multiple of the output 
// bit width or vice versa).
// The asymmetric FIFO controller provides address generation, write-enable logic, flag	logic, and 
// operational error detection logic. Parameterizable features include FIFO depth, almost empty level, 
// almost full level, level of error detection, type of reset (either asynchronous orsynchronous), and 
// byte (or subword) order in a word. These parameters are specfied when the controller is instantiated
// in the design.
//-------------------------------------------------------------------------------------------------
`timescale 1ns / 10ps

module asymfifoctl_s2_sf_bin (
							 clk_push,   //Input clock for push interface   
							 clk_pop,    //Input clock for pop interface
							 rst_n,      //Reset input, active low 
							 push_req_n, //FIFO push request, active low 
							 flush_n,	 //Flushes the partial word into memory (fills in 0's)
							 pop_req_n,  //FIFO pop request, active low 
							 data_in,    //FIFO data to push 
							 rd_data,    //RAM data input to FIFO controller 
							 we_n,       //Write enable output for write port of RAM, active low 
							 push_empty, //Write enable output for write port of RAM, active low 
							 push_ae,    //FIFO almost empty output flag synchronous to clk_push, 
							             //active high (determined by push_ae_lvl parameter) 	 
							 push_hf,    //FIFO half full output flag synchronous to clk_push, 
							             //active high	 	 
							 push_af,    //FIFO almost full output flag synchronous to clk_push, 
							             //active high (determined by push_af_lvl parameter)			 
							 push_full,  //FIFO's RAM full output flag (including the input 
							             //buffer of FIFO controller for data_in_width < 
								         //data_out_width) synchronous to clk_push, active high 
							 ram_full,   //FIFO's RAM (excluding the input buffer of FIFO controller 
							             //for data_in_width < data_out_width) full output flag 
								         //synchronous to clk_push, active high 
							 part_wd,    //Partial word accumulated in the input buffer synchronous
							             //to clk_push, active high (for data_in_width < data_out_width 
								         //only; otherwise, tied low)
							 push_error, //Partial word accumulated in the input buffer synchronous
							             //to clk_push, active high (for data_in_width < data_out_width 
								         //only; otherwise, tied low)
							 pop_empty,  //FIFO empty output flag synchronous to clk_pop, active high
							 pop_ae,     //FIFO almost empty output flag synchronous to clk_pop, 
							             //active high (determined by pop_ae_lvl parameter) 
							 pop_hf,     //FIFO half full output flag synchronous to clk_pop, 
							             //active high
							 pop_af,     //FIFO almost full output flag synchronous to clk_pop, 
							             //active high (determined by pop_af_lvl parameter)
							 pop_full,   //FIFO's RAM full b output flag (excluding the input buffer 
							             //of FIFO controller for case data_in_width < data_out_width) 
								         //synchronous to clk_pop, active high 
							 pop_error,  //FIFO pop error (underrun) output flag synchronous to clk_pop, 
							             //active high 
							 wr_data,    //FIFO controller output data to RAM 
							 wr_addr,    //Address output to write port of RAM 
							 rd_addr,    //Address output to read port of RAM 
							 data_out    //FIFO data to pop
							 
							  )/* synthesis syn_builtin_du = "weak" */;	   
							 
	//Parameter decalration						 
	parameter	data_in_width	= 4;               
	parameter	data_out_width	= 16;
	parameter 	depth		 	= 8; 
	parameter	push_ae_lvl		= 2;
	parameter	push_af_lvl		= 2;
	parameter	pop_ae_lvl		= 2; 
	parameter	pop_af_lvl		= 2;
	parameter	err_mode		= 0;
	parameter	push_sync		= 1; 
	parameter	pop_sync		= 1;
	parameter	rst_mode		= 1;               
	parameter	byte_order		= 0;               
								   				         
	parameter	w1 = data_in_width;  				         
	parameter	w2 = data_out_width; 				         
										   				         
	parameter  k1 = (w1/w2);							         
	parameter  k2 = (w2/w1);                                     
	parameter  k = ( w1 < w2 ) ? (w2 - w1) : (w1 - w2 );

		//log2 implementation for calculating bit width	for addressing RAM
	`define _synp_dep depth                                                                     
    // +* `include "inc_file.inc"
//$Header: //synplicity/map510rc/designware/inc_file.inc#1 $
//-------------------------------------------------------------------------------------------------
//
// Title       : inc_file.inc 
// Design      : Include file for dw_verilog.v 
// Author      : Harish M K
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

	`define POS0 0+(k2>1)+(k2>2)+(k2>4)+(k2>8)+(k2>16)+(k2>32)+(k2>64)+(k2>128)+(k2>256)                  
	`define K22BITS `POS0                               
	                                                                                    
    `define k2_bit_width `K22BITS

	`define POS00 0+(k1>1)+(k1>2)+(k1>4)+(k1>8)+(k1>16)+(k1>32)+(k1>64)+(k1>128)+(k1>256)                  
	`define K12BITS `POS00                             
	                                                                                    
	`define k1_bit_width `K12BITS 
	 parameter cnt_width = ((w1 == w2) ? 2 : ((w1 < w2) ? `k2_bit_width : `k1_bit_width));

	//Input/output declaration
	input								    clk_pop;    			                               
	input 									clk_push;   	                                       
	input 									rst_n;      	                                       
	input									push_req_n; 		                               
	input									pop_req_n;  		                               
	input [data_in_width - 1 : 0]			data_in;    	                                   
 	input [ ( w1 > w2 ? w1 : w2) - 1 : 0]	rd_data;		                           
 	input									flush_n;                                   
 	                                                                                                      
 	output [data_out_width - 1 : 0]	   		data_out;                                  
	output [ ( w1 > w2 ? w1 : w2) - 1 : 0]	wr_data;	                               
	output									ram_full;                 
	output									part_wd;                      
	output [`_synp_bit_width - 1 : 0]		wr_addr;                      
 	output									we_n;                         
 	output [`_synp_bit_width - 1 : 0]		rd_addr;                      
	output		 							push_full;                    
 	output		 							pop_full;                     
 	output		 							push_af;                      
 	output		 							pop_af;                       
 	output		 							push_hf;                      
 	output									pop_hf;                       
 	output		 							pop_ae;                       
 	output		 							push_ae;                      
 	output		 							pop_empty;                    
 	output		 							push_empty;                   
 	output		 							pop_error;                    
 	output		 							push_error;                   

    //Internal signal declarartion 													  
	integer									i;
	//Naming convention used - signal_name_xy
	//Where x -> e = equal, l = lesser, g = greater
	//      y -> s = sync, a = async	
	// data_in_width == data_out_width signal declaration
	wire [data_in_width - 1 : 0] 		    wr_data_e;   
	wire [(`_synp_bit_width - 1) : 0]       wr_addr_e;                           
	wire [(`_synp_bit_width - 1) : 0]       rd_addr_e;                           
	wire                                    we_n_e;                              
	wire                                    rd_en_e;                              
	wire                                    push_full_e;                              
	wire                                    push_empty_e;                             
	wire                                    push_ae_e;                      
	wire                                    push_hf_e;                         
	wire                                    push_af_e;                       
	wire                                    push_error_e;                             
	wire                                    pop_full_e;                              
	wire                                    pop_empty_e;                             
	wire                                    pop_ae_e;                      
	wire                                    pop_hf_e;                         
	wire                                    pop_af_e;                       
	wire                                    pop_error_e;                             
	wire [data_out_width - 1 : 0] 			data_out_e;
	
	// data_in_width > data_out_width signal declaration
	wire [data_in_width - 1 : 0] 		    wr_data_g;   
	wire [(`_synp_bit_width - 1) : 0]       wr_addr_g;                           
	wire [(`_synp_bit_width - 1) : 0]       rd_addr_g;                           
	wire                                    we_n_g;                              
	wire                                    rd_en_g;                             
	reg [ cnt_width - 1 : 0]  				cnt_gs_r;   
	reg [ cnt_width - 1 : 0]  				cnt_ga_r;   
	wire [ cnt_width - 1 : 0] 				cnt_g_r;    
	wire [data_out_width - 1 : 0] 			data_out_g;
	reg [data_out_width - 1 : 0] 			data_out_gs0;
	reg [data_out_width - 1 : 0] 			data_out_ga0;
	reg [data_out_width - 1 : 0] 			data_out_gs1;
	reg [data_out_width - 1 : 0] 			data_out_ga1;
	wire [data_out_width - 1 : 0] 			data_out_gs;
	wire [data_out_width - 1 : 0] 			data_out_ga;  
	wire                                    push_empty_g;                              
	wire                                    pop_empty_g;                              
	wire 								    push_ae_g;             
	wire 								    pop_ae_g;             
	wire 									push_hf_g;             
	wire 									pop_hf_g;             
	wire 									push_af_g;             
	wire 									pop_af_g;             
	wire 									push_full_g;           
	wire 									pop_full_g;           
	wire                                    push_error_g;                             
	wire                                    pop_error_g;                             

	// data_in_width < data_out_width signal declaration
	wire [data_out_width - 1 : 0] 		    wr_data_l;   
	wire [data_out_width - 1 : 0] 		    wr_data_ls;   
	wire [data_out_width - 1 : 0] 		    wr_data_la;   
	wire [data_out_width - 1 : 0] 		    wr_data0_ls;   
	wire [data_out_width - 1 : 0] 		    wr_data1_ls;   
	wire [data_out_width - 1 : 0] 		    wr_data0_la;   
	wire [data_out_width - 1 : 0] 		    wr_data1_la;   
	wire [(`_synp_bit_width - 1) : 0]       wr_addr_l;                           
	wire [(`_synp_bit_width - 1) : 0]       rd_addr_l;                           
	wire                                    we_n_l;                              
	wire                                    rd_en_l;                             
	reg [cnt_width - 1 : 0]  				cnt_ls_r;   
	reg [cnt_width - 1 : 0]  				cnt_la_r;   
	wire [cnt_width - 1 : 0] 				cnt_l_r;    
	wire [data_out_width - 1 : 0] 			data_out_l;
	wire                                    push_empty_l;                              
	wire                                    pop_empty_l;                              
	wire 								    push_ae_l;             
	wire 								    pop_ae_l;             
	wire 									push_hf_l;             
	wire 									pop_hf_l;             
	wire 									push_af_l;             
	wire 									pop_af_l;             
	wire 									push_full_l;           
	wire 									pop_full_l;  
	wire                                    ram_full_l;                              
	reg                                     part_wd_ls;                              
	reg                                     part_wd_la;                              
	wire                                    part_wd_l;                              
	wire                                    push_error_l;                             
	wire                                    pop_error_l;                             
	reg [((w1 < w2)? (k2 - 1 )* data_in_width : ((w1 == w2 ) ? data_in_width : (k1 - 1 )* data_in_width)) - 1 : 0]	data_hold0_ls_r;
	reg [((w1 < w2)? (k2 - 1 )* data_in_width : ((w1 == w2 ) ? data_in_width : (k1 - 1 )* data_in_width)) - 1 : 0]	data_hold1_ls_r;
	reg [((w1 < w2)? (k2 - 1 )* data_in_width : ((w1 == w2 ) ? data_in_width : (k1 - 1 )* data_in_width)) - 1 : 0]	data_hold0_la_r;
	reg [((w1 < w2)? (k2 - 1 )* data_in_width : ((w1 == w2 ) ? data_in_width : (k1 - 1 )* data_in_width)) - 1 : 0]	data_hold1_la_r;

	//Output assignment
	assign rd_addr = w1 < w2 ? rd_addr_l : ( w1 > w2  ? rd_addr_g : rd_addr_e);
	assign wr_addr = w1 < w2 ? wr_addr_l : ( w1 > w2  ? wr_addr_g : wr_addr_e);	
	assign push_full =  w1 < w2 ? push_full_l : ( w1 > w2  ? push_full_g : push_full_e);   
	assign pop_full = w1 < w2 ? pop_full_l : ( w1 > w2  ? pop_full_g : pop_full_e);      
	assign push_af =  w1 < w2 ? push_af_l : ( w1 > w2  ? push_af_g : push_af_e);       
	assign pop_af = w1 < w2 ? pop_af_l : ( w1 > w2  ? pop_af_g : pop_af_e);   
	assign push_hf =  w1 < w2 ? push_hf_l : ( w1 > w2  ? push_hf_g : push_hf_e);       
	assign pop_hf = w1 < w2 ? pop_hf_l : ( w1 > w2  ? pop_hf_g : pop_hf_e);       
	assign pop_ae = w1 < w2 ? pop_ae_l : ( w1 > w2  ? pop_ae_g : pop_ae_e);      
	assign push_ae =  w1 < w2 ? push_ae_l : ( w1 > w2  ? push_ae_g : push_ae_e);       
	assign pop_empty = w1 < w2 ? pop_empty_l : ( w1 > w2  ? pop_empty_g : pop_empty_e);   
	assign push_empty =  w1 < w2 ? push_empty_l : ( w1 > w2  ? push_empty_g : push_empty_e);    
	assign pop_error = w1 < w2 ? pop_error_l : ( w1 > w2  ? pop_error_g : pop_error_e);   
	assign push_error =  w1 < w2 ? push_error_l : ( w1 > w2  ? push_error_g : push_error_e);    
	assign ram_full = w1 < w2 ? ram_full_l : ( w1 > w2  ? push_full_g : push_full_e); 
	assign part_wd =  w1 < w2 ? part_wd_l : 0;
	assign we_n =  w1 < w2 ? we_n_l : ( w1 > w2  ? we_n_g : we_n_e); 
	assign data_out = w1 < w2 ? data_out_l : ( w1 > w2  ? data_out_g : data_out_e);
	assign wr_data = w1 < w2 ? wr_data_l : ( w1 > w2  ? wr_data_g : wr_data_e);
	
	
	/*****************************************************
	* Implementation of data_in_width == data_out_width	 * 
	*****************************************************/
	assign data_out_e = rd_data;
	assign wr_data_e = data_in;	 
	assign rd_en_e = ~pop_req_n & ~pop_empty_e;
	wire write_allow_e = ~push_req_n & ~push_full;
	
	async_fifoctl_bin #( depth, push_ae_lvl, push_af_lvl, pop_ae_lvl, pop_af_lvl, err_mode, push_sync, pop_sync, rst_mode, k2, cnt_width ) equal
	(
	.clk_push(clk_push),
	.clk_pop(clk_pop),
	.rst_n(rst_n),
	.push_req_n(push_req_n),
	.pop_req_n(pop_req_n),
	.write_allow(write_allow_e),  
	.flush_n(),		 
	.part_wd(),
	.ren(rd_en_e), 
	.we_n(we_n_e),
	.push_empty(push_empty_e),
	.push_ae(push_ae_e),
	.push_hf(push_hf_e),
	.push_af(push_af_e),
	.ram_full(push_full_e),
	.push_full(),
	.cnt(),	 
	.ram_error(push_error_e),
	.push_error(),
	.pop_empty(pop_empty_e),
	.pop_ae(pop_ae_e),
	.pop_hf(pop_hf_e),
	.pop_af(pop_af_e),
	.pop_full(pop_full_e),
	.pop_error(pop_error_e),
	.wr_addr(wr_addr_e),
	.rd_addr(rd_addr_e)
	);

	/**************************************************************
	* Implementation of data_in_width == data_out_width	ends here * 
	**************************************************************/
	
	/*****************************************************
	* Implementation of data_in_width > data_out_width	 * 
	*****************************************************/ 
	assign wr_data_g = data_in;	 
	assign rd_en_g = (cnt_g_r == k1 - 1) && !pop_req_n && !pop_empty_g;//Active HIGH signal
	assign data_out_gs = byte_order ? data_out_gs1 : data_out_gs0;
	assign data_out_ga = byte_order ? data_out_ga1 : data_out_ga0;
	assign data_out_g = rst_mode ? data_out_gs : data_out_ga;
	assign cnt_g_r = rst_mode ? cnt_gs_r : cnt_ga_r;
	wire write_allow_g = ~push_req_n & ~push_full;
	
	async_fifoctl_bin #( depth, push_ae_lvl, push_af_lvl, pop_ae_lvl, pop_af_lvl, err_mode, push_sync, pop_sync, rst_mode, k2, cnt_width ) greater
	(
	.clk_push(clk_push),
	.clk_pop(clk_pop),
	.rst_n(rst_n),
	.push_req_n(push_req_n),
	.pop_req_n(pop_req_n),
	.write_allow(write_allow_g),
	.flush_n(), 
	.part_wd(),
	.ren(rd_en_g),
	.we_n(we_n_g),
	.push_empty(push_empty_g),
	.push_ae(push_ae_g),
	.push_hf(push_hf_g),
	.push_af(push_af_g),
	.push_full(),
	.ram_full(push_full_g),
	.cnt(),
	.ram_error(push_error_g),
	.push_error(),
	.pop_empty(pop_empty_g),
	.pop_ae(pop_ae_g),
	.pop_hf(pop_hf_g),
	.pop_af(pop_af_g),
	.pop_full(pop_full_g),
	.pop_error(pop_error_g),
	.wr_addr(wr_addr_g),
	.rd_addr(rd_addr_g)
	);
	
			
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
	always @(posedge clk_pop ) 
      if (!rst_n) 
		  cnt_gs_r <=  {`k1_bit_width{1'b0}};
      else if ( !pop_req_n )
		  begin
			  if ( pop_empty_g )
				  cnt_gs_r <= cnt_gs_r;
		      else if ( cnt_gs_r == k1 - 1 )
				  cnt_gs_r <=  {`k1_bit_width{1'b0}};
			  else  
				  cnt_gs_r <= cnt_gs_r + 1;
		  end
		  
    /**************************************
	    Async. reg implementation										
	***************************************/
 
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
	always @(posedge clk_pop or negedge rst_n) 
      if (!rst_n) 
		  cnt_ga_r <=  {`k1_bit_width{1'b0}};
      else if ( !pop_req_n )
		  begin
			  if ( pop_empty_g )
				  cnt_ga_r <= cnt_ga_r;
		      else if ( cnt_ga_r == k1 - 1 )
				  cnt_ga_r <=  {`k1_bit_width{1'b0}};
			  else  
				  cnt_ga_r <= cnt_ga_r + 1;
		  end	
		  
 	/**************************************************************
	* Implementation of data_in_width > data_out_width	ends here * 
	**************************************************************/

	/***************************************************
	* Implementation of data_in_width < data_out_width *
	***************************************************/
   //part_wd = 0 indicates no data, hence don't write even if flush_n = 0
    assign we_n_l =  ~((cnt_l_r == k2 - 1) && !push_req_n && !ram_full_l ) && ~(!flush_n && part_wd_l && !push_req_n && !ram_full_l ); 
	assign rd_en_l = ~(pop_req_n || pop_empty);//Active HIGH signal 
	assign data_out_l = rd_data;
	assign cnt_l_r = rst_mode ? cnt_ls_r : cnt_la_r;
	assign wr_data_l = rst_mode ? wr_data_ls : wr_data_la;
	assign part_wd_l = rst_mode ? part_wd_ls : part_wd_la; 
	
	//Sync. register implementation
	//Collecting data
    assign wr_data_ls =  byte_order ? wr_data1_ls : wr_data0_ls;  
	assign wr_data0_ls = flush_n ? ((cnt_ls_r == k2 - 1) ? {data_hold0_ls_r, data_in} : {data_hold0_ls_r, {w1{1'b0}}}) : {data_hold0_ls_r, {data_in_width {1'b0}}};
	assign wr_data1_ls = flush_n ? ((cnt_ls_r == k2 - 1) ? {data_in, data_hold1_ls_r} : {{w1{1'b0}}, data_hold1_ls_r}) : {{data_in_width {1'b0}}, data_hold1_ls_r};
	
	//Keep track of sub-word writing
	always @(posedge clk_push ) 
      if (!rst_n) 
		  cnt_ls_r <=  {`k2_bit_width{1'b0}};
	  else if ( !flush_n )
		  cnt_ls_r <= {`k2_bit_width{1'b0}}; 
      else if ( !push_req_n )
		  begin
			  if ( push_full_l && we_n_l )
				  cnt_ls_r <= cnt_ls_r;
		      else if ( cnt_ls_r == k2 - 1 )
				  cnt_ls_r <=  {`k2_bit_width{1'b0}};
			  else  
				  cnt_ls_r <= cnt_ls_r + 1;
		  end			

	//Saving (k2 - 1) data input, byte_order = 0 ( First byte is in MSB position )	  
	always @(posedge clk_push )
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
							if ( cnt_l_r == 0 ) 
								data_hold0_ls_r[data_in_width - 1 : 0] <= data_in;
						end
					else
						begin  	 
							//synthesis loop_limit 2000
							for ( i = 0; i < data_in_width; i = i + 1 )
								data_hold0_ls_r[ (k2 - 2 - cnt_l_r) * data_in_width + i] <= data_in[i];
						end	
					2'b01, 2'b11: data_hold0_ls_r <= data_hold0_ls_r;
					2'b10: 			
					if ( k2 == 2 )
						begin
							if ( cnt_l_r == 0 ) 
								data_hold0_ls_r[data_in_width - 1 : 0] <= data_in;
						end
					else
						begin		 
							//synthesis loop_limit 2000
							for ( i = 0; i < data_in_width; i = i + 1 )
								data_hold0_ls_r[ (k2 - 2 - cnt_l_r) * data_in_width + i] <= data_in[i];
						end		
		        endcase	
			end	

	//Saving (k2 - 1) data input, byte_order = 1 ( First byte is in LSB position )	  
	always @(posedge clk_push )
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
							if ( cnt_l_r == 0 ) 
								data_hold1_ls_r[data_in_width - 1 : 0] <= data_in;
						end
					else
						begin  
							//synthesis loop_limit 2000
							for ( i = 0; i < data_in_width; i = i + 1 )
								data_hold1_ls_r[ cnt_l_r * data_in_width + i] <= data_in[i];
						end	
					2'b01, 2'b11: data_hold1_ls_r <= data_hold1_ls_r;
					2'b10: 			
					if ( k2 == 2 )
						begin
							if ( cnt_l_r == 0 ) 
								data_hold1_ls_r[data_in_width - 1 : 0] <= data_in; //LHS,RHS widths are same
						end
					else
						begin 														 
							//synthesis loop_limit 2000
							for ( i = 0; i < data_in_width; i = i + 1 )
								data_hold1_ls_r[ cnt_l_r * data_in_width + i] <= data_in[i];
						end		
		        endcase	
			end	
			
   	//Generating part_wd
    always @(posedge clk_push ) 
		if (!rst_n) 
			part_wd_ls <= 1'b0;           	 
		else 				  
			begin
				if ( !flush_n || (cnt_ls_r != k2 - 1 && !push_req_n) )
					part_wd_ls <= 1;
				else if ( cnt_ls_r == k2 - 1 && !we_n_l )//( cnt_ls_r == k2 - 1 && !push_req_n ))
					part_wd_ls <= 0;
			end		
	   
 
	//Aync. registers implementation
    assign wr_data_la =  byte_order ? wr_data1_la : wr_data0_la;  
	assign wr_data0_la = flush_n ? ((cnt_la_r == k2 - 1) ? {data_hold0_la_r, data_in} : {data_hold0_la_r, {w1{1'b0}}}) : {data_hold0_la_r, {data_in_width {1'b0}}};
	assign wr_data1_la = flush_n ? ((cnt_la_r == k2 - 1) ? {data_in, data_hold1_la_r} : {{w1{1'b0}}, data_hold1_la_r}) : {{data_in_width {1'b0}}, data_hold1_la_r};

	//Keep track of sub-word writing
	always @(posedge clk_push or negedge rst_n) 
      if (!rst_n) 
		  cnt_la_r <=  {`k2_bit_width{1'b0}};           	 
	  else if ( !flush_n )
		  cnt_la_r <= {`k2_bit_width{1'b0}}; 
      else if ( !push_req_n )
		  begin
			  if ( push_full_l && we_n_l )
				  cnt_la_r <= cnt_la_r;
			  else if ( cnt_la_r == k2 - 1 )
				  cnt_la_r <=  {`k2_bit_width{1'b0}};
			  else  
				  cnt_la_r <= cnt_la_r + 1;
		  end		  
				
	//Saving (k2 - 1) data input, byte_order = 0 ( First byte is in MSB position )	  
	always @(posedge clk_push or negedge rst_n)
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
							if ( cnt_l_r == 0 ) 
								data_hold0_la_r[data_in_width - 1 : 0] <= data_in;
						end
					else
						begin										  
							//synthesis loop_limit 2000
							for ( i = 0; i <  data_in_width; i = i + 1 )
								data_hold0_la_r[ (k2 - 2 - cnt_l_r) * data_in_width + i] <= data_in[i];
						end	
					2'b01, 2'b11: data_hold0_la_r <= data_hold0_la_r;
					2'b10: 			
					if ( k2 == 2 )
						begin
							if ( cnt_l_r == 0 ) 
								data_hold0_la_r[data_in_width - 1 : 0] <= data_in;
						end
					else
						begin						   
							//synthesis loop_limit 2000
							for ( i = 0; i < data_in_width; i = i + 1 )
								data_hold0_la_r[ (k2 - 2 - cnt_l_r) * data_in_width + i] <= data_in[i];
						end		
		        endcase	
			end	

	//Saving (k2 - 1) data input, byte_order = 1 ( First byte is in LSB position )	  
	always @(posedge clk_push or negedge rst_n)
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
							if ( cnt_l_r == 0 ) 
								data_hold1_la_r[data_in_width - 1 : 0] <= data_in;
						end
					else
						begin											 
							//synthesis loop_limit 2000
							for ( i = 0; i < data_in_width; i = i + 1 )
								data_hold1_la_r[ cnt_l_r * data_in_width + i] <= data_in[i];
						end	
					2'b01, 2'b11: data_hold1_la_r <= data_hold1_la_r;
					2'b10: 			
					if ( k2 == 2 )
						begin
							if ( cnt_l_r == 0 ) 
								data_hold1_la_r[data_in_width - 1 : 0] <= data_in;
						end
					else
						begin 										  
							//synthesis loop_limit 2000
							for ( i = 0; i < data_in_width; i = i + 1 )
								data_hold1_la_r[ cnt_l_r * data_in_width + i] <= data_in[i];
						end		
		        endcase	
			end	

	//Generating part_wd
    always @(posedge clk_push or negedge rst_n) 
		if (!rst_n) 
			part_wd_la <= 1'b0;           	 
		else 				  
			begin
				if ( !flush_n ||( cnt_la_r != k2 - 1 && !push_req_n ))
					part_wd_la <= 1;
				else if ( cnt_la_r == k2 - 1 && !we_n_l )
					part_wd_la <= 0;
			end
			
	async_fifoctl_bin #( depth, push_ae_lvl, push_af_lvl, pop_ae_lvl, pop_af_lvl, err_mode, push_sync, pop_sync, rst_mode, k2, cnt_width ) less
	(
	.clk_push(clk_push),
	.clk_pop(clk_pop),
	.rst_n(rst_n),
	.push_req_n(push_req_n),
	.pop_req_n(pop_req_n),
	.write_allow(!we_n_l),
	.flush_n(flush_n),	
	.part_wd(part_wd_l),
	.ren(rd_en_l),
	.we_n(),
	.push_empty(push_empty_l),
	.push_ae(push_ae_l),
	.push_hf(push_hf_l),
	.push_af(push_af_l),
	.push_full(push_full_l),
	.ram_full(ram_full_l),
	.cnt(cnt_l_r),
	.ram_error(),
	.push_error(push_error_l),
	.pop_empty(pop_empty_l),
	.pop_ae(pop_ae_l),
	.pop_hf(pop_hf_l),
	.pop_af(pop_af_l),
	.pop_full(pop_full_l),
	.pop_error(pop_error_l),
	.wr_addr(wr_addr_l),
	.rd_addr(rd_addr_l)
	);
 
	
	
`undef k1_bit_width
`undef K12BITS
`undef POS00
`undef k2_bit_width
`undef K22BITS
`undef POS0
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
