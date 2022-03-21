

//--------------------------------------------------------------------------------------------------
//
// Title       : DW_asymfifoctl_s1_sf
// Design      : DW_asymfifoctl_s1_sf
// Author      : Nithin (Re-Designed as part of DW Integration)

//-------------------------------------------------------------------------------------------------
//
// Description : DW_fifoctl_s1_sf is a FIFO RAM controller designed to interface with a dual-port
// synchronous RAM.
// The input data bit width of DW_asymfifoctl_s1_sf can be different than its output data bit
// width, but must have an integer-multiple relationship (the input bit width being a multiple
// of the output bit width or vice versa). In other words, either of the following conditions
// must be true:
//   The data_in_width = K x data_out_width, or
//   The data_out_width = K x data_in_width
// where K is a positive integer.
// The asymmetric FIFO controller provides address generation, write-enable logic, flag logic
// and operational error detection logic.
//-------------------------------------------------------------------------------------------------

`timescale 1ns/10ps

module DW_asymfifoctl_s1_sf (
														 clk,
														 rst_n,
														 push_req_n,
														 flush_n,
														 pop_req_n,
														 diag_n,
														 data_in,
														 rd_data,
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
														 wr_addr,
														 rd_addr,
														 data_out
														) /* synthesis syn_builtin_du = "weak" */;	
 parameter          data_in_width  = 4;
 parameter          data_out_width = 16;
 parameter          depth          = 10;
 parameter          ae_level       = 1;
 parameter          af_level       = 9;
 parameter          err_mode       = 1;
 parameter          rst_mode       = 1;
 parameter          byte_order     = 0;



`define _synp_addr_width ((depth>4096)? ((depth>262144)? ((depth>2097152)? ((depth>8388608)? 24 : ((depth> 4194304)? 23 : 22)) : ((depth>1048576)? 21 : ((depth>524288)? 20 : 19))) : ((depth>32768)? ((depth>131072)?  18 : ((depth>65536)? 17 : 16)) : ((depth>16384)? 15 : ((depth>8192)? 14 : 13)))) : ((depth>64)? ((depth>512)?  ((depth>2048)? 12 : ((depth>1024)? 11 : 10)) : ((depth>256)? 9 : ((depth>128)? 8 : 7))) : ((depth>8)? ((depth> 32)? 6 : ((depth>16)? 5 : 4)) : ((depth>4)? 3 : ((depth>2)? 2 : 1)))))

localparam max_width 	= ((data_in_width>data_out_width)?data_in_width:data_out_width);
localparam K 					= ((data_in_width>data_out_width)?(data_in_width/data_out_width):(data_out_width/data_in_width));
localparam min_width	= ((data_in_width>data_out_width)?data_out_width:data_in_width);
localparam in_l_out	 	= (data_in_width < data_out_width);
localparam in_e_out  	= (data_in_width == data_out_width);

input [data_in_width-1 : 0]							data_in;
input [max_width-1 : 0]									rd_data;
input																		clk;
input																		rst_n;
input																		push_req_n; 
input																		flush_n; 
input																		pop_req_n; 
input																		diag_n;


output [data_out_width-1 : 0]     			data_out;
output [max_width-1 : 0]         				wr_data;
output [`_synp_addr_width-1 : 0]        wr_addr;
output [`_synp_addr_width-1 : 0]        rd_addr;
output 																	we_n; 
output																	empty; 
output																	almost_empty; 
output																	half_full; 
output																	almost_full;
output 																	full; 
output																	ram_full;
output																	error; 
output																	part_wd;

wire [data_out_width-1 : 0]   				  data_out;
wire [max_width-1 : 0]        					wr_data;
wire [`_synp_addr_width-1 : 0]        	wr_addr;
wire [`_synp_addr_width-1 : 0]        	rd_addr;
wire 																		we_n;
wire																		empty;
wire																		almost_empty;
wire																		half_full;
wire																		almost_full;

wire 																		full; 
wire  																	ram_full; 
wire  																	error;

reg																			part_wd;


reg	[max_width-min_width- 1 : 0]						 input_buf;
reg	[log2_fn(K+1)-1:0]												wd_cntr;

wire [max_width-1 : 0]        								wr_data_l;

reg																						acu_push_req_n;
reg																						wrap_error_l;
reg																						wrap_error_l_nxt;
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


wire																					push_req_n_int;
wire																					pop_req_n_int;
wire																					full_l;

reg	[log2_fn(K+1)-1:0]												rd_cntr;

integer i;
integer j;



DW_fifoctl_s1_sf #(
									 .depth(depth), 
									 .ae_level(ae_level),
                   .af_level(af_level),
                   .err_mode(err_mode),
                   .rst_mode(rst_mode)
                  )
					U_F(
									.clk(clk),
									.rst_n(rst_n),
									.push_req_n(push_req_n_int),
									.pop_req_n(pop_req_n_int),
									.diag_n(diag_n),
									.we_n(we_n),
									.empty(ram_empty),
									.almost_empty(almost_empty),
									.half_full(half_full),
									.almost_full(almost_full),
									.full(ram_full_int),
									.error(ram_error),
									.wr_addr(wr_addr),
									.rd_addr(rd_addr)
							);


assign arst_n = (rst_mode == 0) ? rst_n : 1'b1;

assign push_req_n_int = in_l_out ? acu_push_req_n : in_e_out ? push_req_n : push_req_n_g; 
assign pop_req_n_int	= (in_l_out | in_e_out) ? pop_req_n : pop_req_n_g;
assign empty					= ram_empty;
assign full 					=	in_l_out ? full_l : ram_full_int;
assign ram_full				= ram_full_int;
assign error					=	in_l_out ? (ram_error | wrap_error_l) : in_e_out ? ram_error : (ram_error | wrap_error_g);
assign wr_data				=	in_l_out ? wr_data_l : data_in;
assign data_out				=	(in_l_out | in_e_out) ? rd_data : data_out_g; 

	
// RTL for data_in_width < data_out_width
assign full_l  = ram_full & (wd_cntr == K - 1);
assign empty_l = ram_empty;
assign error_l = (ram_error | wrap_error_l);

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
always @ (posedge clk or negedge arst_n)
	begin
		if((~arst_n && rst_mode == 0) || (~rst_n && rst_mode == 1))
			begin
				wd_cntr <= 0;
				input_buf <= 0;
				wrap_error_l <= 1'b0;
			end
		else
			begin
			 if(!flush_n & part_wd & (!ram_full | (ram_full & !pop_req_n))) 
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
			 else if(!push_req_n & (!full | full & !pop_req_n))
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
				wrap_error_l <= (err_mode	== 0 | err_mode == 1) ? (wrap_error_l_nxt | wrap_error_l) : wrap_error_l_nxt;
			end
	end
end
endgenerate

always @ *
	begin

		part_wd = !(wd_cntr == 0 ) && (data_in_width < data_out_width);
		if( !push_req_n & ( (wd_cntr == K - 1) & (!full | full & !pop_req_n) ) || (!flush_n & part_wd & (!ram_full | (ram_full & !pop_req_n))) )
			acu_push_req_n = 1'b0;
		else
			acu_push_req_n = 1'b1;


   if(ram_full ==1'b1 && (
		(wd_cntr == K - 1 && push_req_n===1'b0) ||
		(part_wd && flush_n === 1'b0)))
	      wrap_error_l_nxt = pop_req_n;
	    else
	      wrap_error_l_nxt = 1'b0;

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

// RTL for data_in_width > data_out_width
// Put a rd counter which will count K - 1 pop's
// If rd counter is K - 1 then generate a pop req
// Data is Multiplexed from rd_data word based
// on the current value of the counter.
generate
if(~in_l_out & ~in_e_out)
begin:gt        
always @ (posedge clk or negedge arst_n)
	begin
		if((~arst_n && rst_mode == 0) || (~rst_n && rst_mode == 1))
			begin
				rd_cntr <= 0;
				wrap_error_g <= 0;
			end
		else			
			begin
				// Sub Word counter
//			if((!pop_req_n & !empty) & ~( (full | empty ) & !push_req_n & !pop_req_n ) )
				if((!pop_req_n & !empty) )
					begin
						if(rd_cntr == K - 1)
							rd_cntr <= 0;
						else
							rd_cntr <= rd_cntr + 1;
					end
	
				wrap_error_g <= (err_mode == 0 || err_mode == 1) ? (wrap_error_g_nxt | wrap_error_g) : wrap_error_g_nxt; 
			end
	end
end
endgenerate
//assign pop_req_n_g = ~( (!pop_req_n & !empty) & (rd_cntr == K - 2) ) | ( (full | empty )& !push_req_n & !pop_req_n );


always @ *
	begin
		// Generate pop at the end of K pop's if the FIFO is not empty
		// Check if the FIFO is not empty or not full if there is a simultaneous push and pop
		if( (!pop_req_n & !empty & (rd_cntr == K - 1) ) & ~(rd_cntr != K-1 & !push_req_n & !pop_req_n & (full | empty)) )
			pop_req_n_g = 1'b0;
		else
			pop_req_n_g = 1'b1;

		if( (!push_req_n & (!full | (full & !pop_req_n_g ))) & ~(!push_req_n & !pop_req_n_g & empty) ) 
			push_req_n_g = 1'b0;
		else
			push_req_n_g = 1'b1;
	end



always @ *
	begin
		for(i=0;i<min_width;i=i+1)
			data_out_g[i] = rd_data[(byte_order == 1 ? rd_cntr : K - 1 - rd_cntr)* min_width + i];
	end

assign wrap_error_g_nxt = ((!push_req_n & full) & (pop_req_n | rd_cntr != K - 1)) | (!pop_req_n & empty);

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
