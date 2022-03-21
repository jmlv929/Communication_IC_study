
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
//
// ABSTRACT: Input registers used for asymmetric data transfer when the
//           input data width is less than and an integer multiple 
//           of the output data width.
//
//		Parameters:	Valid Values
//		==========	============
//              in_width        [ 1 to 256]
//              out_width       [ 1 to 256]
//                  Note: in_width must be less than
//                        out_width and an integer multiple:
//                        that is, out_width = K * in_width
//              err_mode        [ 0 = sticky error flag,
//                                1 = dynamic error flag ]
//              byte_order      [ 0 = the first byte (or subword) is in MSBs
//                                1 = the first byte  (or subword)is in LSBs ]
//              flush_value     [ 0 = fill empty bits of partial word with 0's upon flush
//                                1 = fill empty bits of partial word with 1's upon flush ]
//		
//		Input Ports 	Size	Description
//		===========  	====	===========
//		clk_push	1 bit	Push I/F Input Clock
//		rst_push_n	1 bit	Async. Push Reset (active low)
//		init_push_n	1 bit	Sync. Push Reset (active low)
//              push_req_n      1 bit   Push Request (active low)
//              data_in         M bits  Data subword being pushed
//              flush_n         1 bit   Flush the partial word into
//                                      the full word memory (active low)
//              fifo_full       1 bit   Full indicator of RAM/FIFO
//
//		Output Ports 	Size	Description
//		============ 	====	===========
//              push_wd_n       1 bit   Full word ready for transfer (active low)
//              data_out        N bits  Data word into RAM or FIFO
//              inbuf_full      1 bit   Inbuf registers all contain active data_in subwords
//              part_wd         1 bit   Partial word pushed flag
//              push_error      1 bit   Overrun of RAM or FIFO (includes inbuf registers)
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



module DW_asymdata_inbuf(
	clk_push,
	rst_push_n,
	init_push_n,
	push_req_n,
	data_in,
	flush_n,
        fifo_full,

	push_wd_n,
	data_out,
        inbuf_full,
        part_wd,
        push_error
        // _model_constraint_1
	);

parameter in_width     = 8;  // RANGE 1 to 256
parameter out_width    = 16; // RANGE 1 to 256
parameter err_mode     = 0;  // RANGE 0 to 1
parameter byte_order   = 0;  // RANGE 0 to 1   
parameter flush_value  = 0;  // RANGE 0 to 1
   

input  			clk_push;	// clk
input  			rst_push_n;	// active low async reset
input  			init_push_n;	// active low sync reset
input  			push_req_n;	// active low push reqest
input   [in_width-1:0]  data_in;        // data subword
input 			flush_n;	// flush partial word (active low)
input                   fifo_full;      // Full indicator of RAM/FIFO

output 			push_wd_n;	// ready to write full data word (active low)
output  [out_width-1:0] data_out;       // full data word
output                  inbuf_full;     // Inbuf registers all contain active data_in subwords
output                  part_wd;        // Partial word pushed flag
output                  push_error;     // Overrun of RAM or FIFO (includes inbuf registers)


reg     [out_width-1:0] data_out;

localparam K = (out_width/in_width);
localparam cnt_width  =  (((out_width/in_width)>16)?(((out_width/in_width)>64)?(((out_width/in_width)>128)?8:7):(((out_width/in_width)>32)?6:5)):(((out_width/in_width)>4)?(((out_width/in_width)>8)?4:3):(((out_width/in_width)>2)?2:1)));
localparam [0:0] flush_value_1bit  = (flush_value == 1) ? 1'b1 : 1'b0;
localparam [cnt_width-1:0] km1 = (out_width/in_width) - 1;
localparam [cnt_width-1:0] km2 = (out_width/in_width) - 2;

reg   [(in_width*(K-1))-1:0]  data_reg;
reg   [(in_width*(K-1))-1:0]  next_data_reg;

reg   [cnt_width-1:0] cntr;
wire  [cnt_width:0]   next_cntr;

wire                      flush_valid;

reg                       inbuf_full;
wire                      next_inbuf_full;

reg                       part_wd;
wire                      next_part_wd;

reg                       push_error;
wire                      next_push_error;
wire                      pre_next_push_error;

wire  [31:0]              one;
reg   [cnt_width-1:0]     temp;


// Sized constants
assign one = 1;             // used as counter preset value and comparing to counter value

// derive internal 'flush' signal
assign  flush_valid  = ~flush_n && ~fifo_full && part_wd;

// inbuf_full status bit
assign  next_inbuf_full  = (((cntr == km2) && ~push_req_n && ~flush_valid) ||
			    ((K == 2) && (cntr == one[cnt_width-1:0]) && ~push_req_n && flush_valid)) ? 1'b1 :
			     (flush_valid || ((~push_req_n && inbuf_full) && !fifo_full)) ? 1'b0 : inbuf_full;

assign next_cntr  = ((push_req_n == 1'b0) && !(inbuf_full && fifo_full)) ?
                      ((flush_valid == 1'b1) ?
                         one[cnt_width-1:0] :
                         (cntr == km1) ? 
                           {cnt_width{1'b0}} : 
                           (cntr + one[cnt_width-1:0])) :
                      ((flush_valid == 1'b1) ?
		        {cnt_width{1'b0}} : cntr);


// derive part_wd (next)
generate
  if (cnt_width == 1) begin : GEN_CW1
    assign  next_part_wd  = next_cntr[0];
  end else begin : GEN_CW0
    assign  next_part_wd  = |next_cntr[cnt_width-1:0];
  end
endgenerate


// derive push_error (Note: err_mode = 0 causes sticky behavior only clear by reset)
assign  pre_next_push_error  = ((~flush_n && part_wd) || (~push_req_n && inbuf_full)) && fifo_full;
generate
  if (err_mode == 0) begin : GEN_NXT_PE_EM0
    assign  next_push_error = pre_next_push_error | push_error;
  end else begin : GEN_NXT_PE_EM1
    assign  next_push_error = pre_next_push_error;
  end
endgenerate

always @(push_req_n or data_in or cntr or flush_valid or data_reg) begin : PROC_NEXT_DATA_REG
  integer w_sw, w_b;
  integer i;
 
  if (push_req_n == 1'b0) begin
    if (flush_valid == 1'b0) begin
      for (w_sw=0; w_sw<K-1; w_sw=w_sw+1) begin
        for (i=0;i<cnt_width;i=i+1) temp[ i ] = (((w_sw>>i)&1)!=0)?1'b1:1'b0;
        for (w_b=0; w_b<in_width; w_b=w_b+1) begin
          if (cntr == temp)
            next_data_reg[(in_width*w_sw)+w_b] = data_in[w_b];
	  else if ((cntr == {cnt_width{1'b0}}) && (w_sw != 0))

              next_data_reg[(in_width*w_sw)+w_b] = flush_value_1bit;
          else
            next_data_reg[(in_width*w_sw)+w_b] = data_reg[(in_width*w_sw)+w_b];

        end // for-loop of write_bits
      end // for-loop of write_subword
    end else begin  // flush_valid = 1, place data_in subword in lower-most bits
      // first subword gets data_in
      // the rest, fill in flush value
      for (w_sw=0; w_sw<K-1; w_sw=w_sw+1) begin
        for (w_b=0; w_b<in_width; w_b=w_b+1) begin
	  if (w_sw == 0)
	    next_data_reg[w_b] = data_in[w_b];
          else

            next_data_reg[(in_width*w_sw)+w_b] = flush_value_1bit;

        end // for-loop of write_bits
      end // for-loop of write_subword
    end  // (flush_valid == 1'b1)
  end else begin
    for (w_sw=0; w_sw<K-1; w_sw=w_sw+1) begin
      for (w_b=0; w_b<in_width; w_b=w_b+1) begin
        next_data_reg[(in_width*w_sw)+w_b] = data_reg[(in_width*w_sw)+w_b];
      end // for-loop of write_bits
    end // for-loop of write_subwords
  end
end

assign push_wd_n  = ((push_req_n || (cntr != km1)) && (flush_n || ~part_wd)) || fifo_full;



generate
  if (byte_order == 0) begin : GEN_DOUT_BO_EQ_0
    always @(data_reg or data_in or flush_valid) begin : PROC_DATA_REG_BO0
      integer r_sw, r_b;
      integer b;
      integer dout_idx, dreg_idx;

      for (r_sw=0; r_sw<(K-1); r_sw=r_sw+1) begin
        for (r_b=0; r_b<in_width; r_b=r_b+1) begin
          dout_idx = (in_width*((K-1)-r_sw))+r_b;
          dreg_idx = (in_width*r_sw)+r_b;

          data_out[dout_idx] = data_reg[dreg_idx];

        end  // for-loop of read_bits
      end  // for-loop of read_subwords
      if (flush_valid == 1'b1) begin
        data_out[in_width-1:0] = {in_width{flush_value_1bit}};
      end else begin
        for (b=0; b<in_width; b=b+1) begin
          data_out[b] = data_in[b];
        end
      end
    end
  end else begin : GEN_DOUT_BO_EQ_1
    always @(data_reg or data_in or flush_valid) begin : PROC_DATA_REG_BO1
      integer r_sw, r_b;
      integer b;
      integer dout_fv_idx;

      for (r_sw=0; r_sw<(K-1); r_sw=r_sw+1) begin
        for (r_b=0; r_b<in_width; r_b=r_b+1) begin
          data_out[(in_width*r_sw)+r_b] = data_reg[(in_width*r_sw)+r_b];
        end  // for-loop of read_bits
      end  // for-loop of read_subwords
      if (flush_valid == 1'b1) begin
        for (b=0; b<in_width; b=b+1) begin
          dout_fv_idx = in_width*(K-1)+b;

          data_out[dout_fv_idx] = flush_value_1bit;

        end
      end else begin
        for (b=0; b<in_width; b=b+1) begin
          dout_fv_idx = in_width*(K-1)+b;

          data_out[dout_fv_idx] = data_in[b];

        end
      end
    end
  end
endgenerate


always @(posedge clk_push or negedge rst_push_n) begin : inbuf_registers
  if (rst_push_n == 1'b0) begin
    data_reg   <= {(in_width*(K-1)){1'b0}};
    cntr       <= {cnt_width{1'b0}};
    part_wd    <= 1'b0;
    inbuf_full <= 1'b0;
    push_error <= 1'b0;
  end else if (init_push_n == 1'b0) begin
    data_reg   <= {(in_width*(K-1)){1'b0}};
    cntr       <= {cnt_width{1'b0}};
    part_wd    <= 1'b0;
    inbuf_full <= 1'b0;
    push_error <= 1'b0;
  end else begin
    data_reg   <= next_data_reg;
    cntr       <= next_cntr[cnt_width-1:0];
    part_wd    <= next_part_wd;
    inbuf_full <= next_inbuf_full;
    push_error <= next_push_error;
  end 
end
endmodule
