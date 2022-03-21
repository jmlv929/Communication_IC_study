

//--------------------------------------------------------------------------------------------------
//
// Title       : DW_asymfifoctl_s2_sf.v
// Design      : DW_asymfifoctl_s2_sf 
// Author      : Nithin (Re-Designed as part of DW Integration)

//
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
module DW_asymfifoctl_s2_sf	(
															 clk_push,   //Input clock for push interface   
															 clk_pop,    //Input clock for pop interface
															 rst_n,      //Reset input, active low 
															 push_req_n, //FIFO push request, active low 
															 flush_n,	 	//Flushes the partial word into memory (fills in 0's)
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
															 push_error, //Push Error(overflow) output flagsynchronous
																				 //to clk_push, active high
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
	              
parameter	data_in_width		= 4;               
parameter	data_out_width	= 16;
parameter depth		 				= 8; 
parameter	push_ae_lvl			= 2;
parameter	push_af_lvl			= 2;
parameter	pop_ae_lvl			= 2; 
parameter	pop_af_lvl			= 2;
parameter	err_mode				= 0;
parameter	push_sync				= 1; 
parameter	pop_sync				= 1;
parameter	rst_mode				= 1;               
parameter	byte_order			= 0;               
							   				         
`define _synp_addr_width ((depth>4096)? ((depth>262144)? ((depth>2097152)? ((depth>8388608)? 24 : ((depth> 4194304)? 23 : 22)) : ((depth>1048576)? 21 : ((depth>524288)? 20 : 19))) : ((depth>32768)? ((depth>131072)?  18 : ((depth>65536)? 17 : 16)) : ((depth>16384)? 15 : ((depth>8192)? 14 : 13)))) : ((depth>64)? ((depth>512)?  ((depth>2048)? 12 : ((depth>1024)? 11 : 10)) : ((depth>256)? 9 : ((depth>128)? 8 : 7))) : ((depth>8)? ((depth> 32)? 6 : ((depth>16)? 5 : 4)) : ((depth>4)? 3 : ((depth>2)? 2 : 1)))))

localparam max_width 	= ((data_in_width>data_out_width)?data_in_width:data_out_width);
localparam K 					= ((data_in_width>data_out_width)?(data_in_width/data_out_width):(data_out_width/data_in_width));
localparam min_width	= ((data_in_width>data_out_width)?data_out_width:data_in_width);
localparam in_l_out	 	= (data_in_width < data_out_width);
localparam in_e_out  	= (data_in_width == data_out_width);

//Input/output declaration
input																		clk_pop;    			                               
input																		clk_push;   	                                       
input																		rst_n;      	                                       
input																		push_req_n; 		                               
input																		pop_req_n;  		                               
input [data_in_width-1:0]								data_in;    	                                   
input [max_width-1:0]										rd_data;		                           
input																		flush_n;                                   
																																																							
output [data_out_width-1:0]							data_out;                                  
output [max_width - 1 : 0]							wr_data;	                               
output																	ram_full;                 
output																	part_wd;                      
output [`_synp_addr_width-1:0]					wr_addr;                      
output																	we_n;                         
output [`_synp_addr_width-1:0]					rd_addr;                      
output																	push_full;                    
output																	pop_full;                     
output																	push_af;                      
output																	pop_af;                       
output																	push_hf;                      
output																	pop_hf;                       
output																	pop_ae;                       
output																	push_ae;                      
output																	pop_empty;                    
output																	push_empty;                   
output																	pop_error;                    
output																	push_error; 

reg																			part_wd;

wire																					push_req_n_int;
wire																					pop_req_n_int;


reg	[max_width-min_width- 1 : 0]						 	input_buf;
reg	[log2_fn(K+1)-1:0]												wd_cntr;

wire [max_width-1 : 0]        								wr_data_l;

reg																						acu_push_req_n;
reg																						wrap_error_l;
reg																						wrap_error_l_nxt;
reg																						push_error_l;
reg																						push_error_l_nxt;

wire [max_width-1 : 0]         								data_0;
wire [max_width-1 : 0]         								data_1;
reg	 [max_width-1 : 0]         								data_tmp;

wire [max_width-1 : 0]         								dout_0;
wire [max_width-1 : 0]         								dout_1;
reg	 [max_width-1 : 0]         								dout_tmp;
wire [max_width-1 : 0]												dout_g;
reg	 [min_width-1 : 0]												data_out_g;
reg																						pop_req_n_g;
reg																						push_req_n_g;
wire																					wrap_error_g_nxt;
reg																						wrap_error_g;
wire																					push_error_g_nxt;
reg																						push_error_g;
wire																					pop_error_g_nxt;
reg																						pop_error_g;

wire																					full_l;

reg	[log2_fn(K+1)-1:0]												rd_cntr;

integer i;
integer j;

assign arst_n = (rst_mode == 0) ? rst_n : 1'b1;

 DW_fifoctl_s2_sf  #(
										  .depth(depth), 
                      .push_ae_lvl(push_ae_lvl), 
                      .push_af_lvl(push_af_lvl), 
                      .pop_ae_lvl(pop_ae_lvl),
                      .pop_af_lvl(pop_af_lvl), 
                      .err_mode(err_mode), 
                      .push_sync(push_sync), 
                      .pop_sync(pop_sync),
                      .rst_mode(rst_mode) 
										)

							U_F	(  .clk_push(clk_push), 
                     .clk_pop(clk_pop),
                     .rst_n(rst_n), 
                     .push_req_n(push_req_n_int),
                     .pop_req_n(pop_req_n_int), 
                     .we_n(we_n),
                     .push_empty(push_empty), 
                     .push_ae(push_ae),
                     .push_hf(push_hf), 
                     .push_af(push_af),
                     .push_full(ram_push_full),
                     .push_error(ram_push_error),
                     .pop_empty(pop_empty_int),
                     .pop_ae(pop_ae),
                     .pop_hf(pop_hf), 
                     .pop_af(pop_af), 
                     .pop_full(ram_pop_full),
                     .pop_error(ram_pop_error), 
                     .wr_addr(wr_addr), 
                     .rd_addr(rd_addr),
								     .push_word_count(),
								     .pop_word_count(),
								     .test(1'b0)
									);


assign push_req_n_int = in_l_out ? acu_push_req_n : in_e_out ? push_req_n : push_req_n_g; 
assign pop_req_n_int	= (in_l_out | in_e_out) ? pop_req_n : pop_req_n_g;
assign push_full 			=	in_l_out ? full_l : ram_push_full;
assign pop_empty			=	pop_empty_int;
assign pop_error			=	(in_l_out | in_e_out) ? ram_pop_error : pop_error_g | ram_pop_error; 
assign ram_full				= ram_push_full;
assign wr_data				=	in_l_out ? wr_data_l : data_in;
assign data_out				=	(in_l_out | in_e_out) ? rd_data : data_out_g; 
assign push_error			=	in_l_out ? (ram_push_error | push_error_l) : in_e_out ? ram_push_error : (ram_push_error | push_error_g); 
assign pop_full				=	ram_pop_full;

 // RTL for data_in_width < data_out_width
assign full_l  = ram_push_full & (wd_cntr == K - 1);

// Put a word counter which will count K - 1 pushes
// Generate a push_req when the counter reaches K - 1 
// and if there is a push and also at the corner 
// conditions full & pop | flush and ram_full and pop
// Put a shift register into which data will be 
// shifted when ever there is a push and if count != K - 1
// If there is a flush shift the wr_data so that it is at
// the MSB position
generate
if(in_l_out)
begin:lt        
always @ (posedge clk_push or negedge arst_n)
	begin
		if((~arst_n && rst_mode == 0) || (~rst_n && rst_mode == 1))
			begin
				wd_cntr <= 0;
				input_buf <= 0;
				wrap_error_l <= 1'b0;
				push_error_l <= 1'b0;
			end
		else
			begin
			 if(!flush_n & part_wd & !ram_full) 
				begin
					if(!push_req_n)					
						begin
							wd_cntr <= 1;
					  	input_buf <= {{max_width-min_width{1'b0}},data_in};
						end
					else
						begin
							wd_cntr <= 0;
						  input_buf <= 0;		
						end
				end
			 // Byte counter to count number of pushes
			 else if(!push_req_n & !push_full)
				begin
					if(wd_cntr == K - 1)
						begin
							wd_cntr <= 0;
							input_buf <= {input_buf,data_in};
						end
					else
						begin
							wd_cntr <= wd_cntr + 1;
							if(wd_cntr != K - 1)
								input_buf <= {input_buf,data_in};
						end
				end
				wrap_error_l <= (err_mode	== 0) ? (wrap_error_l_nxt | wrap_error_l) : wrap_error_l_nxt;

				push_error_l <= (err_mode	== 0) ? (push_error_l_nxt | push_error_l) : push_error_l_nxt;
			end
	end
end
endgenerate


always @ *
	begin

		part_wd = !(wd_cntr == 0 ) && (data_in_width < data_out_width);
		if( (!push_req_n & ((wd_cntr == K - 1) & !push_full)) || (!flush_n & part_wd & !ram_full) ) 
			acu_push_req_n = 1'b0;
		else
			acu_push_req_n = 1'b1;

   if(ram_full ==1'b1 && (
		(wd_cntr == K - 1 && push_req_n===1'b0) ||
		(part_wd && flush_n === 1'b0)))
	      wrap_error_l_nxt = 1'b1;
	    else
	      wrap_error_l_nxt = 1'b0;

   if(ram_full ==1'b1 && (
		(wd_cntr == K - 1 && push_req_n===1'b0) ||
		(part_wd && flush_n === 1'b0)))
	      push_error_l_nxt = 1'b1;
	    else
	      push_error_l_nxt = 1'b0;
	end

assign data_0			= flush_n ? {input_buf,data_in} : {(input_buf << ((wd_cntr < K - 1 ? K - 1 - wd_cntr : 0)*data_in_width)) ,{data_in_width{1'b0}}};
assign data_1 		= data_tmp;
assign wr_data_l 	= (byte_order == 0) ? data_0 : data_1;

always @ *
	begin
		for(j=0;j<K;j=j+1)
			for(i=0;i<min_width;i=i+1)
				data_tmp[j*min_width + i] = data_0[(K-1-j)*min_width + i];
	end



generate
if(~in_l_out & ~in_e_out)
begin:gt        
always @ (posedge clk_push or negedge arst_n)
  begin
    if((~arst_n && rst_mode == 0) || (~rst_n && rst_mode == 1))            
      push_error_g <= 1'b0;
    else  
    	push_error_g <= (err_mode == 0) ? (push_error_g_nxt | push_error_g) : push_error_g_nxt;
  end
// RTL for data_in_width > data_out_width
// Put a rd counter which will count K - 1 pop's
// If rd counter is K - 1 then generate a pop req
// Data is Multiplexed from rd_data word based
// on the current value of the counter.
always @ (posedge clk_pop or negedge arst_n)
	begin
		if((~arst_n && rst_mode == 0) || (~rst_n && rst_mode == 1))
			begin
				rd_cntr 			<= 0;
				wrap_error_g	<= 0;
				pop_error_g 	<= 0;
			end
		else			
			begin
				// Sub Word counter
//			if((!pop_req_n & !empty) & ~( (full | empty ) & !push_req_n & !pop_req_n ) )
				if((!pop_req_n & !pop_empty) )
					begin
						if(rd_cntr == K - 1)
							rd_cntr <= 0;
						else
							rd_cntr <= rd_cntr + 1;
					end
	
				wrap_error_g <= (err_mode == 0)  ? (wrap_error_g_nxt | wrap_error_g) : wrap_error_g_nxt;
				pop_error_g  <= (err_mode == 0) ? (pop_error_g_nxt | pop_error_g) : pop_error_g_nxt;
			end
	end

end
endgenerate

//assign pop_req_n_g = ~( (!pop_req_n & !empty) & (rd_cntr == K - 2) ) | ( (full | empty )& !push_req_n & !pop_req_n );


always @ *
	begin
		// Generate pop at the end of K pop's if the FIFO is not empty
		// Check if the FIFO is not empty or not full if there is a simultaneous push and pop
		if( (!pop_req_n & !pop_empty & (rd_cntr == K - 1) ) ) 
			pop_req_n_g = 1'b0;
		else
			pop_req_n_g = 1'b1;

		if(!push_req_n & !push_full) 
			push_req_n_g = 1'b0;
		else
			push_req_n_g = 1'b1;
	end



always @ *
	begin
		for(i=0;i<min_width;i=i+1)
			data_out_g[i] = rd_data[(byte_order == 1 ? rd_cntr : K - 1 - rd_cntr)* min_width + i];
	end

assign wrap_error_g_nxt = (!push_req_n & push_full) | (!pop_req_n & pop_empty);

assign push_error_g_nxt	= (!push_req_n & push_full); 
assign pop_error_g_nxt	=	(!pop_req_n & pop_empty);

function integer log2_fn; 
	input integer n;
	integer i;
	integer j;
	begin
		for(i=0;(2**i)<n;i=i+1)
			j = i;

			j = j + 1;
		log2_fn = j;
	end
endfunction	

`undef _synp_addr_width

endmodule
