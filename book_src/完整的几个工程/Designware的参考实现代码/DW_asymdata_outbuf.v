
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
//
// ABSTRACT: Asymmetric Data Transfer Output Buffer Synthetic Model
//           Output multiplexer used for asymmetric data transfers when the
//           input data width is greater than and an integer multiple 
//           of the output data width.
//
//		Parameters:	Valid Values
//		==========	============
//              in_width        [ 1 to 256]
//              out_width       [ 1 to 256]
//                  Note: in_width must be greater than
//                        out_width and an integer multiple:
//                        that is, in_width = K * out_width
//              err_mode        [ 0 = sticky error flag,
//                                1 = dynamic error flag ]
//              byte_order      [ 0 = the first byte (or subword) is in MSBs
//                                1 = the first byte  (or subword)is in LSBs ]
//		
//		Input Ports 	Size	Description
//		===========  	====	===========
//		clk_pop	        1 bit	Pop I/F Input Clock
//		rst_pop_n	1 bit	Async. Pop Reset (active low)
//		init_pop_n	1 bit	Sync. Pop Reset (active low)
//              pop_req_n       1 bit   Active Low Pop Request
//              data_in         M bits  Data 'full' word being popped
//              fifo_empty      1 bit   Empty indicator from fifoctl that RAM/FIFO is empty
//
//		Output Ports 	Size	Description
//		============ 	====	===========
//              pop_wd_n        1 bit   Full word for transfered (active low)
//              data_out        N bits  Data subword into RAM or FIFO
//              part_wd         1 bit   Partial word poped flag
//              pop_error       1 bit   Underrun of RAM or FIFO (includes outbuf registers)
//
//		  Note:	M is the value of the parameter in_width
//		       	N is the value of the parameter out_width
//		
//		
// MODIFIED:
//
//              DLL   6-15-11  Enhanced coding style to remove Leda warnings.
//                             Mainly pre-conditioning indexing inside loops and changing
//                             constant conditionaly expressions into generate
//                             blocks.
//
//              DLL   1-10-07  Converted looping variables from global to local
//
////////////////////////////////////////////////////////////////////////////////



module DW_asymdata_outbuf(
	clk_pop,
	rst_pop_n,
	init_pop_n,
	pop_req_n,
	data_in,
        fifo_empty,

	pop_wd_n,
	data_out,
        part_wd,
        pop_error
        // Embedded dc_shell script
        // _model_constraint_1
	);

parameter in_width     = 16; // RANGE 1 to 256
parameter out_width    =  8; // RANGE 1 to 256
parameter err_mode     =  0; // RANGE 0 to 1
parameter byte_order   =  0; // RANGE 0 to 1   
   

input  			clk_pop;	// clk
input  			rst_pop_n;	// active low async reset
input  			init_pop_n;	// active low sync reset
input  			pop_req_n;	// active high pop reqest
input   [in_width-1:0]  data_in;        // data full word
input                   fifo_empty;     // empty indicator from fifoctl that RAM/FIFO is empty

output 			pop_wd_n;	// full data word read
output  [out_width-1:0] data_out;       // data subword
output                  part_wd;        // Partial word poped flag
output                  pop_error;      // Underrun of RAM or FIFO


wire    [out_width-1:0] data_out;


localparam K = (in_width/out_width);
localparam cnt_width  = (((in_width/out_width)>16)?(((in_width/out_width)>64)?(((in_width/out_width)>128)?8:7):(((in_width/out_width)>32)?6:5)):(((in_width/out_width)>4)?(((in_width/out_width)>8)?4:3):(((in_width/out_width)>2)?2:1)));
localparam [cnt_width-1:0] km1 = (in_width/out_width) - 1;

reg   [in_width-1:0]      data_in_int;

reg   [cnt_width-1:0]     cntr;
wire  [cnt_width:0]       next_cntr;

reg                       part_wd;
wire                      next_part_wd;

reg                       pop_error;
wire                      next_pop_error;
wire                      pre_next_pop_error;

wire  [31:0]              one;

// Sized constants
assign one = 1;             // used to increment counter

assign next_cntr  = ((pop_req_n == 1'b0) && !fifo_empty) ?
                      ((cntr == km1) ? 
                        {cnt_width{1'b0}} : 
                        (cntr + one[cnt_width-1:0])) :
	 	      cntr;

generate
  if (cnt_width == 1) begin : GEN_CW1
    assign  next_part_wd  = next_cntr[0];
  end else begin : GEN_CW0
    assign  next_part_wd  = |next_cntr[cnt_width-1:0];
  end
endgenerate

// derive pop_error
assign  pre_next_pop_error  = ~pop_req_n && fifo_empty;
generate
  if (err_mode == 0) begin : GEN_EM0
    assign  next_pop_error = pre_next_pop_error | pop_error;
  end else begin : GEN_EM1
    assign  next_pop_error = pre_next_pop_error;
  end
endgenerate


assign pop_wd_n  = (pop_req_n || (cntr != km1)) || fifo_empty;

generate
  if (byte_order == 0) begin : GEN_BO_EQ_0
    always @(data_in) begin : PROC_DATA_IN_INT
      integer  r_sw, r_b;
      integer  di_int_idx_tmp;
      integer  di_idx_tmp; 
      for (r_sw=0; r_sw<K; r_sw=r_sw+1) begin
        for (r_b=0; r_b<out_width; r_b=r_b+1) begin
          di_int_idx_tmp = (out_width*((K-1)-r_sw))+r_b;
          di_idx_tmp     = (out_width*r_sw)+r_b;

          data_in_int[di_int_idx_tmp] = data_in[di_idx_tmp];

        end  // for-loop of read_bits
      end  // for-loop of read_subwords
    end
  end else begin : GEN_BO_EQ_1
    always @(data_in) begin : PROC_DATA_IN_INT
      integer  r_sw, r_b;
      integer  di_idx_tmp;
      for (r_sw=0; r_sw<K; r_sw=r_sw+1) begin
        for (r_b=0; r_b<out_width; r_b=r_b+1) begin
          di_idx_tmp = (out_width*r_sw)+r_b;

          data_in_int[di_idx_tmp] = data_in[di_idx_tmp];

        end  // for-loop of read_bits
      end  // for-loop of read_subwords
    end
  end
endgenerate


  function [out_width-1:0] func_read_mux ;
    input [out_width*K-1:0]	a;	// input bus
    input [cnt_width-1:0]  	sel;	// select
    reg   [out_width-1:0]	z;
    integer			i, j, k;
    begin
      z = {out_width {1'b0}};
      j = 0;
      k = 0;   // Temporary fix for a Leda issue
      for (i=0 ; i<K ; i=i+1) begin
	if (i == sel) begin
	  for (k=0 ; k<out_width ; k=k+1) begin
	    z[k] = a[j + k];
	  end // for (k
	end // if
	j = j + out_width;
      end // for (i
      func_read_mux  = z;
    end
  endfunction

  assign data_out = func_read_mux ( data_in_int, cntr );



always @(posedge clk_pop or negedge rst_pop_n) begin : outbuf_registers
  if (rst_pop_n == 1'b0) begin
    cntr       <= {cnt_width{1'b0}};
    part_wd    <= 1'b0;
    pop_error  <= 1'b0;
  end else if (init_pop_n == 1'b0) begin
    cntr       <= {cnt_width{1'b0}};
    part_wd    <= 1'b0;
    pop_error  <= 1'b0;
  end else begin
    cntr       <= next_cntr[cnt_width-1:0];
    part_wd    <= next_part_wd;
    pop_error  <= next_pop_error;
  end 
end
endmodule
