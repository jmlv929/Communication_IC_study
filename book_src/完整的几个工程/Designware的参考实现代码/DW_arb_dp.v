
//
////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////
// ABSTRACT:  Arbiter with dynamic priority scheme
//   
// MODIFIED:
//                                      
// 10/07/2011  RJK   Added full labeling of all regions of generate
//                   statement code
//
// 10/13/2010  RJK   Corrected the "lock from park state" issue
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//      Parameters      Valid Values    Description
//      ==========      =========       ===========
//      n               {2 to 32}       Number of arbiter clients
//      park_mode       {0 to 1}        Enable/Disable parking of grant
//      park_index      {0 to 31}       Park the grant to default      
//      output_mode     {0 to 1}        Enable/disable registered outputs   
//      index_width     {1 to 5}        ceil(log2(n))
//      real_index_width {2 to 6}       ceil(log2(n+1))
//      
//      Input Ports   Size              Description
//      ===========   ====              ============
//      clk             1               Input clock
//      rst_n           1               Active low reset
//      init_n          1               Active low synchronous reset
//      enable          1               Active high enable
//      request         n               Input request from clients
//      prior           n*ceil(log2(n)) Priority vector from all clients  
//      lock            n               lock the grant to the current request
//      mask            n               Input to mask specific request
//      locked          1               Flag to indicate locked condition
//      parked          1               Flag to indicate that there are no
//                                      requesting clients and the the grant
//                                      of resources has defauled to park_index
//      granted         1               Flag to indicate that arbiter has
//                                      granted the resource to one of the
//                                      requesting clients
//      grant           n               Grant output   
//      grant_index     ceil(log2(n))   Index of the current grant
//
// Modification history:
//                                      
// 10/13/2010 RJK Corrected "lock from park state" issue
//                                      
//  7/14/2011 RJK Updates for Leda lint checking
//
////////////////////////////////////////////////////////////////////////////////

  module DW_arb_dp (
	clk,
	rst_n,
	init_n,
	enable,
	request,
	prior,
	lock,
	mask,
	parked,
	granted,
	locked,
	grant,
	grant_index
    // Embedded dc_shell script
    // _model_constraint_1
);


  parameter n           = 4; // RANGE 2 to 32
  parameter park_mode   = 1; // RANGE 0 or 1
  parameter park_index  = 0; // RANGE 0 to (n - 1)
  parameter output_mode = 1; // RANGE 0 or 1

  `define DW_index_width  (((n>16)?((n>64)?((n>128)?8:7):((n>32)?6:5)):((n>4)?((n>8)?4:3):((n>2)?2:1))))
  `define DW_real_index_width  (((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1))))

  localparam [`DW_index_width-1:0]	INITIAL_GRANT_INDEX = (park_mode==0)? -1 : park_index;
  localparam [n-1 : 0]		INITIAL_GRANT       = (park_mode==0)? 0 : (1 << park_index);


  input				clk;	 // Clock input
  input				rst_n;	 // active low reset
  input				init_n;	 // active low reset
  input				enable;	 // active high register enable
  input  [n-1: 0]		request; // client request bus
  input  [`DW_index_width*n-1: 0]	prior;	 // client priority bus
  input  [n-1: 0]		lock;	 // client lock bus
  input  [n-1: 0]		mask;	 // client mask bus
  
  output			parked;	 // arbiter parked status flag
  output			granted; // arbiter granted status flag
  output			locked;	 // arbiter locked status flag
  output [n-1: 0]		grant;	 // one-hot client grant bus
  output [`DW_index_width-1: 0]	grant_index; //	 index of current granted client


localparam [`DW_real_index_width-1 : 0] maxp1_priority = (n == (1 << `DW_index_width))?
							n : ((1 << `DW_index_width) -1);

reg    [n-1: 0] next_grant;
wire   [`DW_index_width-1: 0] next_grant_index;
wire   next_parked, next_granted, next_locked;

reg    [n-1: 0] grant_int;
reg    [`DW_index_width-1: 0] grant_index_int;
reg    parked_int, granted_int, locked_int;

wire   [n-1: 0] masked_req;

wire   [n-1: 0] temp_gnt;

reg    [(n*`DW_real_index_width)-1: 0] priority_vec;

reg    [n*`DW_real_index_width-1: 0] muxed_pri_vec;

wire   [`DW_index_width-1: 0] current_index;

wire   [`DW_real_index_width-1: 0] priority_value;



  assign masked_req = request & ~mask;

  assign next_locked = granted_int & |(grant_int & lock);

  assign next_granted = next_locked | (|masked_req);

  assign next_parked = ~next_granted;


  always @(prior or masked_req) begin : PROC_reorder_input
    integer i1, j1;
    for (i1=0 ; i1<n ; i1=i1+1) begin
      for (j1=0 ; j1<`DW_real_index_width ; j1=j1+1) begin
	priority_vec[i1*`DW_real_index_width+j1] = (j1 == `DW_index_width) ?
          1'b0: prior[i1*`DW_index_width+j1];
	muxed_pri_vec[i1*`DW_real_index_width+j1] = (masked_req[i1]) ?
          ((j1 == `DW_index_width)?  1'b0: prior[i1*`DW_index_width+j1]) : maxp1_priority[j1];
      end
    end
  end


  
    DW_minmax #(`DW_real_index_width, n) U_minmax (
		.a(muxed_pri_vec),
		.tc(1'b0),
		.min_max(1'b0),
		.value(priority_value),
		.index(current_index) );


  
  function [n-1:0] func_decode;
    input [`DW_index_width-1:0]		A;	// input
    reg   [n-1:0]		z;
    integer			i;
    begin
      z = {n{1'b0}};
      for (i=0 ; i<n ; i=i+1) begin
	if (i == A) begin
	  z [i] = 1'b1;
	end // if
      end // for (i
      func_decode = z;
    end
  endfunction

  assign temp_gnt = func_decode( current_index );


  always @(next_parked or next_locked or grant_int or temp_gnt) begin : PROC_mk_nxt_gr
    case ({next_parked, next_locked}) 
      2'b00: next_grant = temp_gnt;
      2'b01: next_grant = grant_int;
      2'b10: next_grant = INITIAL_GRANT;
      default: next_grant = grant_int;
    endcase
  end


  
  function [`DW_index_width-1:0] func_binenc;
    input [n-1:0]		a;	// input
    reg   [`DW_index_width-1:0]		z;
    integer			i,j;
    begin
      z = {`DW_index_width{1'b1}};
      for (i=n ; i > 0 ; i=i-1) begin
        j = i-1;
	if (a[j] == 1'b1)
	  z = j [`DW_index_width-1:0];
      end // for (i
      func_binenc = z;
    end
  endfunction

  assign next_grant_index = func_binenc( next_grant );


  always @(posedge clk or negedge rst_n) begin : PROC_regs
    if (rst_n == 1'b0) begin
      parked_int          <= 1'b1;
      granted_int         <= 1'b0;
      locked_int          <= 1'b0;
      grant_index_int     <= INITIAL_GRANT_INDEX;
      grant_int           <= INITIAL_GRANT;
    end else if (init_n == 1'b0) begin
      parked_int          <= 1'b1;
      granted_int         <= 1'b0;
      locked_int          <= 1'b0;
      grant_index_int     <= INITIAL_GRANT_INDEX;
      grant_int           <= INITIAL_GRANT;
    end else if (enable) begin
      grant_index_int     <= next_grant_index;
      parked_int          <= next_parked;
      granted_int         <= next_granted;
      locked_int          <= next_locked;
      grant_int           <= next_grant;
    end
  end

  generate if (output_mode == 0)
    begin : GEN_OM_EQ_0
      assign grant	= ((next_locked==1'b0)? next_grant : grant_int) &
				  {n{init_n}};
      assign grant_index	= ((next_locked==1'b0)? next_grant_index : grant_index_int) | 
				  {`DW_index_width{~init_n}};
      assign granted	= ((next_locked==1'b0)? next_granted : granted_int) & init_n;
      assign locked	= next_locked & init_n;
    end else begin : GEN_OM_NE_0
      assign grant	= grant_int;
      assign grant_index	= grant_index_int;
      assign granted	= granted_int;
      assign locked	= locked_int;
    end
  endgenerate

  generate
    if (park_mode == 0) begin : GEN_PM_EQ_0
      assign parked = 1'b0;
    end else if (output_mode == 0) begin : GEN_PM_NE_0_OM_EQ_0
      assign parked	= ((next_locked==1'b0)? next_parked : parked_int) & init_n;
    end else begin : GEN_PM_NE_0_OM_NE_0
      assign parked	= parked_int;
    end
  endgenerate

endmodule
