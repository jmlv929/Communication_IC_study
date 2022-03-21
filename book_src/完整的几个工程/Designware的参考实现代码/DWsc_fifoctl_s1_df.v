////////////////////////////////////////////////////////////////////////////////
//
//       This confidential and proprietary software may be used only
//     as authorized by a licensing agreement from Synopsys Inc.
//     In the event of publication, the following notice is applicable:
//
//
//       The entire notice above must be reproduced on all authorized
//     copies.
//
//          4/14/04
//
// VERSION:   Verilog Synthesis Model for DW_fifoctl_s1_df
//
// DesignWare_version: 472e961b
// DesignWare_release: G-2012.06-DWBB_201206.1
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
// ABSTRACT: Synchronous with Dynamic Flags  
//           dynamic programmable almost empty and almost full flags
//
//           This FIFO controller designed to interface to synchronous
//           true dual port RAMs.
//
//              Parameters:     Valid Values
//              ==========      ============
//              depth           [ 2 to 16777216 ]
//              err_mode        [ 0 = sticky error flag w/ ptr check,
//                                1 = sticky error flag (no ptr chk),
//                                2 = dynamic error flag ]
//		addr_width	ceil(log2(depth))
//              gang_all_status Placeholder, not used in this architecture
//              
//              Input Ports:    Size    Description
//              ===========     ====    ===========
//              clk             1 bit   Input Clock
//              rst_n           1 bit   Active Low Async. Reset
//		init_n		1 bit   Active Low Sync. Reset
//              push_req_n      1 bit   Active Low Push Request
//              pop_req_n       1 bit   Active Low Pop Request
//              diag_n          1 bit   Active Low diagnostic control
//              ae_level        N bits  Almost Empty Level
//              af_thresh       N bits  Almost Full Threshold
//
//              Output Ports    Size    Description
//              ============    ====    ===========
//              we_n            1 bit   Active low Write Enable (to RAM)
//              empty           1 bit   Empty Flag
//              almost_empty    1 bit   Almost Empty Flag
//              half_full       1 bit   Half Full Flag
//              almost_full     1 bit   Almost Full Flag
//              full            1 bit   Full Flag
//              error           1 bit   Error Flag
//              wr_addr         N bits  Write Address (to RAM)
//              rd_addr         N bits  Read Address (to RAM)
//              wrd_count       N bits  Words in FIFO (may not be accurate when full)
//		nxt_empty_n	1 bit   Next state of empty flag (inverted)
//		nxt_full	1 bit   Next state of full flag
//		nxt_error	1 bit   Next state of error flag
//
//                Note: the value of N for wr_addr and rd_addr is
//                      the value of the parameter 'addr_width'
//                      which should be set to the value :
//                              ceil( log2( depth ) )
//              
//
//
// MODIFIED: 
//       10/06/07  DLL  Added parameter 'gang_all_status' to match
//                      low-power architecture.  This parameter is
//                      unused for this implementation.
//
//
////////////////////////////////////////////////////////////////////////////////

module DWsc_fifoctl_s1_df (
    clk,
    rst_n,
    init_n,
    push_req_n,
    pop_req_n,
    diag_n,
    ae_level,
    af_thresh,
    we_n,
    empty,
    almost_empty,
    half_full,
    almost_full,
    full,
    error,
    wr_addr,
    rd_addr,
    wrd_count,
    nxt_empty_n,
    nxt_full,
    nxt_error
    // Embedded dc_shell script
    // _model_constraint_1
    );

parameter depth  = 4;		// RANGE 2 to 16777216
parameter err_mode  =  0 ;	// RANGE 0 to 2
parameter addr_width = 2;	// RANGE 1 to 24
parameter gang_all_status = 0;  // RANGE 0 to 1

input			clk;		// Input Clock (pos edge)
input			rst_n;		// Async reset (active low)
input			init_n;		// Sync reset (active low) (FIFO clear/flush)
input			push_req_n;	// Push request (active low)
input			pop_req_n;	// Pop Request (active low)
input			diag_n;		// Diagnostic sync. reset rd_addr (active low)
input  [addr_width-1:0]	ae_level;	// Almost empty level input bus
input  [addr_width-1:0]	af_thresh;	// Almost full threshold input bus
output			we_n;		// RAM Write Enable output (active low)
output			empty;		// FIFO Empty flag output (active high)
output			almost_empty;	// FIFO Almost Empty flag output (active high)
output			half_full;	// FIFO Half Full flag output (active high)
output			almost_full;	// FIFO almost Full flag output (active high)
output			full;		// FIFO full flag output (active high)
output			error;		// FIFO Error flag output (active high)
output [addr_width-1:0]	wr_addr;	// RAM Write Address output bus
output [addr_width-1:0]	rd_addr;	// RAM Read Address output bus
output [addr_width-1:0]	wrd_count;	// Words in FIFO (not always accurate at full)
output			nxt_empty_n;	// Look ahead empty flag (active low)
output			nxt_full;	// Look ahead full flag
output			nxt_error;	// Look ahead empty flag


wire			next_empty_n;
reg			empty_n;
wire			next_almost_empty_n;
reg			almost_empty_n;
wire			next_half_full;
reg			half_full_int;
wire			next_almost_full;
reg			almost_full_int;
wire			next_full;
reg			full_int;
wire			next_error;
reg			error_int;
wire   [addr_width-1:0]	next_wr_addr;
reg    [addr_width-1:0]	wr_addr_int;
wire			next_wr_addr_at_max;
reg			wr_addr_at_max;
wire   [addr_width-1:0]	next_rd_addr;
reg    [addr_width-1:0]	rd_addr_int;
wire			next_rd_addr_at_max;
reg			rd_addr_at_max;
wire   [addr_width-1:0]	next_word_count;
reg    [addr_width-1:0]	word_count;
reg    [addr_width  :0]	advanced_word_count;

wire			advance_wr_addr;
wire   [addr_width+1:0]	advanced_wr_addr;
wire			advance_rd_addr;
wire   [addr_width+1:0]	advanced_rd_addr;
wire			inc_word_count;
wire			dec_word_count;

localparam [addr_width-1 : 0] LastAddress   =  depth - 1;
localparam [addr_width-1 : 0] HF_thresh_val = (depth + 1)/2;
localparam [addr_width   : 0] addrP1_sized_one = 1;

  assign we_n = push_req_n | (full_int & pop_req_n);


  assign advance_wr_addr = ~(push_req_n | (full_int & pop_req_n));

  assign advance_rd_addr = ~pop_req_n  & empty_n;


  assign advanced_wr_addr = {wr_addr_int,advance_wr_addr} + addrP1_sized_one;
  assign next_wr_addr = (wr_addr_at_max  &advance_wr_addr)?
				{addr_width{1'b0}} :
				advanced_wr_addr[addr_width:1];

  assign advanced_rd_addr = {rd_addr_int,advance_rd_addr} + addrP1_sized_one;

  assign next_rd_addr_at_max = ((next_rd_addr & LastAddress) == LastAddress)? 1'b1 : 1'b0;

  assign next_wr_addr_at_max = ((next_wr_addr & LastAddress) == LastAddress)? 1'b1 : 1'b0;

  assign inc_word_count = ~push_req_n & pop_req_n & ~full_int |
			  ~push_req_n & ~empty_n;

  assign dec_word_count = push_req_n & ~pop_req_n & empty_n;

  always @ (word_count or dec_word_count) begin : PROC_infer_incdec
    if (dec_word_count)
      advanced_word_count = word_count - 1;
    else
      advanced_word_count = word_count + 1;
  end

  assign next_word_count = ((inc_word_count | dec_word_count) == 1'b0)?
				word_count : advanced_word_count[addr_width-1:0];

  assign next_full =	((word_count == LastAddress)? ~push_req_n & pop_req_n : 1'b0) |
			(full_int & push_req_n & pop_req_n) |
			(full_int & ~push_req_n);

  assign next_empty_n = (next_word_count == {addr_width{1'b0}})? next_full : 1'b1;


  assign next_half_full = (next_word_count >= HF_thresh_val)? 1'b1 : next_full;


generate
  if ((1<<addr_width) == depth) begin : GEN_PWR2
    assign next_almost_empty_n = ~(((next_word_count <= ae_level)? 1'b1 : 1'b0) &
				 ~next_full);
  end else begin : GEN_NOT_PWR2
    assign next_almost_empty_n = ~((next_word_count <= ae_level)? 1'b1 : 1'b0);
  end
endgenerate


  assign next_almost_full = (next_word_count >= af_thresh)? 1'b1 :
				next_full;


generate
  if (err_mode == 0) begin : GEN_EM_EQ0
    assign next_rd_addr = ((rd_addr_at_max & advance_rd_addr) || (diag_n==1'b0))?
			    {addr_width{1'b0}} : advanced_rd_addr[addr_width:1];
    assign next_error =  (~pop_req_n & ~empty_n) | (~push_req_n & pop_req_n & full_int) |
			 (( |(wr_addr_int ^ rd_addr_int)) ^ (empty_n & ~full_int)) | error_int;
  end
  
  if (err_mode == 1) begin : GEN_EM_EQ1
    assign next_rd_addr =  (rd_addr_at_max & advance_rd_addr)?
			    {addr_width{1'b0}} : advanced_rd_addr[addr_width:1];
    assign next_error = (~pop_req_n & ~empty_n) | (~push_req_n & pop_req_n & full_int) | error_int;
  end
  
  if (err_mode == 2) begin : GEN_EM_EQ2
    assign next_rd_addr =  (rd_addr_at_max & advance_rd_addr)?
			    {addr_width{1'b0}} : advanced_rd_addr[addr_width:1];
    assign next_error = (~pop_req_n & ~empty_n) | (~push_req_n & pop_req_n & full_int);
  end
endgenerate


  always @ (posedge clk or negedge rst_n) begin : PROC_registers
    if (rst_n == 1'b0) begin
      empty_n          <= 1'b0;
      almost_empty_n   <= 1'b0;
      half_full_int    <= 1'b0;
      almost_full_int  <= 1'b0;
      full_int         <= 1'b0;
      error_int        <= 1'b0;
      wr_addr_int      <= {addr_width{1'b0}};
      rd_addr_at_max   <= 1'b0;
      wr_addr_at_max   <= 1'b0;
      rd_addr_int      <= {addr_width{1'b0}};
      word_count       <= {addr_width{1'b0}};
    end else if (init_n == 1'b0) begin
      empty_n          <= 1'b0;
      almost_empty_n   <= 1'b0;
      half_full_int    <= 1'b0;
      almost_full_int  <= 1'b0;
      full_int         <= 1'b0;
      error_int        <= 1'b0;
      rd_addr_at_max   <= 1'b0;
      wr_addr_at_max   <= 1'b0;
      wr_addr_int      <= {addr_width{1'b0}};
      rd_addr_int      <= {addr_width{1'b0}};
      word_count       <= {addr_width{1'b0}};
    end else begin
      empty_n          <= next_empty_n;
      almost_empty_n   <= next_almost_empty_n;
      half_full_int    <= next_half_full;
      almost_full_int  <= next_almost_full;
      full_int         <= next_full;
      error_int        <= next_error;
      rd_addr_at_max   <= next_rd_addr_at_max;
      wr_addr_at_max   <= next_wr_addr_at_max;
      wr_addr_int      <= next_wr_addr;
      rd_addr_int      <= next_rd_addr;
      word_count       <= next_word_count;
    end
  end

  assign empty = ~empty_n;
  assign almost_empty = ~almost_empty_n;
  assign half_full = half_full_int;
  assign almost_full = almost_full_int;
  assign full = full_int;
  assign error = error_int;
  assign wr_addr = wr_addr_int;
  assign rd_addr = rd_addr_int;
  assign wrd_count = word_count;
  assign nxt_empty_n = next_empty_n | ~init_n;
  assign nxt_full    = next_full    &  init_n;
  assign nxt_error   = next_error   &  init_n;

endmodule
