
//
////////////////////////////////////////////////////////////////////////////////

// ABSTRACT:  Arbiter with first-come-first-served priority scheme
//   
// MODIFIED:
////////////////////////////////////////////////////////////////////////////////
//
// ABSTRACT :
//	Arbiter  First-Come-First-Served arbitraton schemes.
//      Parameters      Valid Values    Description
//      ==========      =========       ===========
//      n               {2 to 32}       Number of arbiter clients
//      park_mode       {0 to 1}        Enable/Disable parking of grant
//      park_index      {0 to n-1}      Park the grant to default
//      output_mode     {0 to 1}        Registered or unregistered outputs    
//      
//      Input Ports   Size              Description
//      ===========   ====              ============
//      clk             1               Input clock
//      rst_n           1               Active low reset
//      init_n          1               Active low synchronous reset
//      enable          1               Active high enable
//      request         n               Input request from clients
//      mask            n               Input mask for each client
//      lock            n               lock the grant to the current request
//      
//      Output Ports   Size              Description
//      ===========   ====              ============  
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
// 10/07/2011 RJK Added full labeling of all regions of generate
//                statement code
//
// 10/13/2010 RJK Corrected "lock from park state" issue
//
//  7/14/2011 RJK Updates for Leda lint message cleanup
//
////////////////////////////////////////////////////////////////////////////////
  module DW_arb_fcfs (
	clk,
	rst_n,
        init_n,
	enable,
	request,
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

  parameter n                = 4; // RANGE 2 to 32
  parameter park_mode        = 1; // RANGE 0 or 1
  parameter park_index       = 0; // RANGE 0 to (n - 1)
  parameter output_mode      = 1; // RANGE 0 or 1
`define DW_index_width ((n>16)?((n>64)?((n>128)?8:7):((n>32)?6:5)):((n>4)?((n>8)?4:3):((n>2)?2:1)))



  input				clk;	 // clock input
  input				rst_n;	 // active low reset
  input				init_n;	 // active low reset
  input				enable;	 // active high register enable
  input  [n-1: 0]		request; // client request bus
  input  [n-1: 0]		lock;	 // client lock bus
  input  [n-1: 0]		mask;	 // client mask bus

  output			parked;	 // arbiter parked status flag
  output			granted; // arbiter granted status flag
  output			locked;	 // arbeter locked status bus
  output [n-1: 0]		grant;	 // one-hot granted client bus
  output [`DW_index_width-1: 0]	grant_index; //ndex of current granted client 




wire   [1:0] current_state, next_state_ff, st_vec;
reg    [1:0] next_state, state_ff;

reg    [n-1: 0] next_grant;
wire   [`DW_index_width-1: 0] next_grant_index;
wire   next_parked, next_granted, next_locked;

reg    [n-1: 0] grant_int;
wire   [`DW_index_width-1: 0] grant_index_int;
reg    parked_int, granted_int, locked_int;


localparam [((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1)))-1 : 0]	maxp1_priority = (n > ((1 << `DW_index_width) - 1))?  n : ((1 << `DW_index_width) - 1);
localparam [((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1)))-1 : 0]	max_prior      = ((n > ((1 << `DW_index_width) - 1))?  n : ((1 << `DW_index_width) - 1)) - 1;
wire   [n-1: 0] masked_req;


wire   [(n*((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1))))-1: 0] prior, next_priority_ff;
reg    [(n*((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1))))-1: 0] priority_ff;

reg    [(n*((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1))))-1: 0] decr_prior;

reg    [(n*((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1))))-1: 0] priority_vec;

reg    [(n*((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1))))-1: 0] muxed_pri_vec;

reg    [(n*((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1))))-1: 0] next_prior;

wire   [`DW_index_width-1: 0] current_index;

wire   [((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1)))-1: 0] priority_value;

wire   [n-1: 0] temp_gnt;

localparam [n-1 : 0]	park_gnt = (park_mode == 0)? 0 : (1 << park_index);

reg    [`DW_index_width-1: 0] grant_index_n_int;
wire   [`DW_index_width-1: 0] next_grant_index_n;


  assign masked_req = request & ~mask;

  assign next_locked = granted_int & |(grant_int & lock);

  assign next_granted = next_locked | (|masked_req);

  assign next_parked = ~next_granted;


  always @(prior or masked_req) begin : PROC_reorder_input
    integer i1, j1;
    for (i1=0 ; i1<n ; i1=i1+1) begin
      for (j1=0 ; j1<((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1))) ; j1=j1+1) begin
	priority_vec[i1*((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1)))+j1] = (j1 == `DW_index_width) ?
          1'b0: prior[i1*((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1)))+j1];
	muxed_pri_vec[i1*((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1)))+j1] = (masked_req[i1]) ?
          priority_vec[i1*((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1)))+j1]: maxp1_priority[j1];
      end
    end
  end

  always @(prior) begin : PROC_predec
    integer i2, j2, k2;
    reg  [(((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1))))-1: 0] temp_prior, temp2_prior;
    for (i2=0 ; i2<n ; i2=i2+1) begin
      for (j2=0 ; j2<((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1))) ; j2=j2+1) begin
        temp_prior[j2] = prior[i2*((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1)))+j2];
      end

      temp2_prior = temp_prior - 1'b1;

      for (k2=0 ; k2<((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1))) ; k2=k2+1) begin
        decr_prior[i2*((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1)))+k2] = temp2_prior[k2];
      end

    end
  end


  assign st_vec = {next_parked, next_locked};

  always @(current_state or st_vec) begin : PROC_mk_nxt_st
    case (current_state)
    2'b00: begin
      case (st_vec)
      2'b00: next_state = 2'b10;
      2'b10: next_state = 2'b01;
      default: next_state = 2'b00;
      endcase
    end
    2'b01: begin
      case (st_vec)
      2'b00: next_state = 2'b10;
      2'b01: next_state = 2'b11;
      default: next_state = 2'b01;
      endcase
    end
    2'b10: begin
      case (st_vec)
      2'b01: next_state = 2'b11;
      2'b10: next_state = 2'b01;
      default: next_state = 2'b10;
      endcase
    end
    default: begin
      case (st_vec)
      2'b00: next_state = 2'b10;
      2'b10: next_state = 2'b01;
      default: next_state = 2'b11;
      endcase
    end
    endcase
  end

  assign current_state = state_ff ^ 2'b00;
  assign next_state_ff = next_state ^ 2'b00;

  always @(current_state or masked_req or next_grant or prior or
                    next_locked or decr_prior) begin : PROC_mk_nxt_prior
    integer i3, j3;
    for (i3=0 ; i3<n ; i3=i3+1) begin
      for (j3=0 ; j3<((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1))) ; j3=j3+1) begin
        case (current_state)
        2'b00: begin
          if (masked_req[i3]) begin
            if (next_grant[i3]) begin
              next_prior[i3*((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1)))+j3] = max_prior[j3];
            end else begin
              next_prior[i3*((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1)))+j3] = decr_prior[i3*((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1)))+j3];
            end
          end else begin
            next_prior[i3*((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1)))+j3] = max_prior[j3];
          end
        end
        2'b01: begin
          if (next_locked) begin
            if (masked_req[i3]) begin
              if (next_grant[i3]) begin
                next_prior[i3*((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1)))+j3] = prior[i3*((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1)))+j3];
              end else begin
                next_prior[i3*((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1)))+j3] = decr_prior[i3*((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1)))+j3];
              end
            end else begin
              next_prior[i3*((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1)))+j3] = max_prior[j3];
            end
          end else begin
            if (masked_req[i3]) begin
              if (next_grant[i3]) begin
                next_prior[i3*((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1)))+j3] = max_prior[j3];
              end else begin
                next_prior[i3*((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1)))+j3] = decr_prior[i3*((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1)))+j3];
              end
            end else begin
              next_prior[i3*((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1)))+j3] = max_prior[j3];
            end
          end
        end
        default: begin
          if (next_locked) begin
            if (masked_req[i3] == 1'b0) begin
              next_prior[i3*((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1)))+j3] = max_prior[j3];
            end else begin
              next_prior[i3*((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1)))+j3] = prior[i3*((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1)))+j3];
            end
          end else begin
            if (masked_req[i3] == 1'b0) begin
              next_prior[i3*((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1)))+j3] = max_prior[j3];
            end else begin
              if (next_grant[i3]) begin
                next_prior[i3*((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1)))+j3] = max_prior[j3];
              end else begin
                next_prior[i3*((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1)))+j3] = decr_prior[i3*((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1)))+j3];
              end
            end
          end
        end

        endcase
      end
    end
  end


  
    DW_minmax #(((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1))), n) U_minmax (
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


  always @(next_parked or next_locked or grant_int or park_gnt or temp_gnt) begin : PROC_mk_nxt_gr
    case ({next_parked, next_locked}) 
    2'b00: next_grant = temp_gnt;
    2'b01: next_grant = grant_int;
    2'b10: next_grant = park_gnt;
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
      state_ff            <= 2'b00;
      priority_ff         <= {n*((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1))){1'b0}};
      grant_index_n_int   <= {`DW_index_width{1'b0}};
      parked_int          <= 1'b0;
      granted_int         <= 1'b0;
      locked_int          <= 1'b0;
      grant_int           <= {n{1'b0}};
    end else if (init_n == 1'b0) begin
      state_ff            <= 2'b00;
      priority_ff         <= {n*((n+1>16)?((n+1>64)?((n+1>128)?8:7):((n+1>32)?6:5)):((n+1>4)?((n+1>8)?4:3):((n+1>2)?2:1))){1'b0}};
      grant_index_n_int   <= {`DW_index_width{1'b0}};
      parked_int          <= 1'b0;
      granted_int         <= 1'b0;
      locked_int          <= 1'b0;
      grant_int           <= {n{1'b0}};
    end else if (enable) begin
      state_ff            <= next_state_ff;
      priority_ff         <= next_priority_ff;
      grant_index_n_int   <= next_grant_index_n;
      parked_int          <= next_parked;
      granted_int         <= next_granted;
      locked_int          <= next_locked;
      grant_int           <= next_grant;
    end
  end

  assign next_priority_ff = {n{max_prior}} ^ next_prior;
  assign prior = {n{max_prior}} ^ priority_ff;

  assign next_grant_index_n  = ~next_grant_index;
  assign grant_index_int     = ~grant_index_n_int;

  generate if (output_mode == 0)
    begin : GEN_OM_EQ_0
      assign grant	= next_grant & {n{init_n}};
      assign grant_index = next_grant_index | {`DW_index_width{~init_n}};
      assign granted	= next_granted & init_n;
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
      assign parked	= next_parked & init_n;
    end else begin : GEN_PM_NE_0_OM_NE_0
      assign parked	= parked_int;
    end
  endgenerate

endmodule
