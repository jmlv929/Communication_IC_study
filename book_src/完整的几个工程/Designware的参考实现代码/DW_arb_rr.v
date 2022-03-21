
////////////////////////////////////////////////////////////////////////////////

//
// ABSTRACT:  Arbiter with round-robin priority scheme
//   
// MODIFIED:
////////////////////////////////////////////////////////////////////////////////
//
// ABSTRACT :
//    Arbiter  Round-Robin arbitraton scheme.
//      Parameters      Valid Values    Description
//      ==========      =========       ===========
//      n               {2 to 32}       Number of arbiter clients
//      output_mode     {0 to 1}        Registered or unregistered outputs    
//      
//      Input Ports   Size              Description
//      ===========   ====              ============
//      clk             1               Input clock
//      rst_n           1               Active low reset
//      init_n          1               Active low synchronous reset
//      enable          1               Active high enable
//      request         n               Input request from clients
//      mask            n bits          Setting mask(i) high will disable request(i)
//      
//      Output Ports   Size              Description
//      ===========   ====              ============  
//      grant           n               Grant output    
//      grant_index     ceil(log2(n))   Index of the current grant
//
// Modification history:
//
//     7-08-11   DLL   Edits made to clean up Leda warnings.
//
////////////////////////////////////////////////////////////////////////////////
  module DW_arb_rr (
    clk,
    rst_n,
    init_n,
    enable,
    request,
    mask,
    granted,
    grant,
    grant_index
    // Embedded dc_shell script
    // _model_constraint_1
);

  parameter n           = 4; // RANGE 2 to 32
  parameter output_mode = 1; // RANGE 0 or 1
`define DW_index_width ((n>16)?((n>64)?((n>128)?8:7):((n>32)?6:5)):((n>4)?((n>8)?4:3):((n>2)?2:1)))

  input                clk;     // clock input
  input                rst_n;   // active low async reset
  input                init_n;  // active low sync  reset
  input                enable;  // active high register enable
  input  [n-1: 0]      request; // client request bus
  input  [n-1: 0]      mask;	// client mask bus

  output                    granted; // arbiter granted status flag
  output [n-1: 0]           grant;   // one-hot granted client bus
  output [`DW_index_width-1: 0] grant_index; //index of current granted client 

  reg                       req_ro; 
  reg                       grant_ro; 
  reg  [`DW_index_width-1: 0]   token_cs;
  reg  [`DW_index_width-1: 0]   token_ns;
  reg  [n-1: 0]             grant_cs;
  reg  [n-1: 0]             grant_ns;
  reg                       granted_r;
  reg  [`DW_index_width-1: 0]   grant_indxr; // count memory
  reg  [`DW_index_width-1: 0]   grant_indxn; // count memory

  localparam [`DW_index_width-1: 0]  one_iw   = 1;
  localparam [`DW_index_width: 0]    one_iwp1 = 1;

  wire [n-1: 0]             masked_req;
  assign masked_req = request & ~mask;


  always@(posedge clk or negedge rst_n) begin : REQUEST_STATE_SEQ_PROC
    if(rst_n == 1'b0) begin
      token_cs    <= {n{1'b0}};
      grant_cs    <= {n{1'b0}};
      grant_indxr <= {n{1'b0}};
      granted_r   <= 1'b0;
    end else if (init_n == 1'b0) begin
      token_cs    <= {n{1'b0}};
      grant_cs    <= {n{1'b0}};
      grant_indxr <= {n{1'b0}};
      granted_r   <= 1'b0;
    end else begin // not busy
      token_cs    <= token_ns;
      grant_cs    <= grant_ns;
      grant_indxr <= grant_indxn;
      granted_r   <= grant_ro;
    end
  end
  always@(masked_req or token_cs or granted_r or enable) begin : masked_req_STATE_COMB_PROC
    reg  [`DW_index_width:0]       maxindx, count;
    reg  [`DW_index_width+1:0]     maxindx_p1;
    reg  [`DW_index_width:0]       next_token_ns_tmp;
    reg  [`DW_index_width: 0]      token_cs_p1;


    grant_ro          = 1'b0;
    grant_ns          = {n{1'b0}};
    token_ns          = {`DW_index_width{1'b0}};
    grant_indxn       = {`DW_index_width{1'b0}};
    req_ro            = |masked_req;
    maxindx_p1        = {`DW_index_width{1'b0}};
    next_token_ns_tmp = {`DW_index_width+1{1'b0}};
    token_cs_p1       = token_cs + one_iw;

    if(enable) begin
      if(masked_req[token_cs] == 1'b1)begin//grant owned by token owner
        grant_ns           = {n{1'b0}};
        grant_ns[token_cs] = 1'b1;
        token_ns           = token_cs;
        grant_indxn        = token_cs_p1[`DW_index_width-1:0];
        grant_ro           = 1'b1;
      end else if(req_ro) begin // req not the token owner, search for next
        for(count = 0 ; count < n; count = count + 1) begin
	  maxindx   = ((n - 1 - count + token_cs) >= n) 
	             ? (token_cs - count - 1) : (n - 1 - count + token_cs);
          maxindx_p1 = maxindx + one_iwp1;

          if(masked_req[maxindx] == 1'b1)begin

            grant_ns            = {n{1'b0}};

            grant_ns[maxindx]     = 1'b1;

            token_ns            = maxindx;
            grant_indxn         = maxindx_p1[`DW_index_width-1:0];
            grant_ro            = 1'b1;
          end 
	end
      // all masked_reqers go to zero while last grant active
      end else if(granted_r == 1'b1 & req_ro == 1'b0)begin 
        next_token_ns_tmp = (token_cs == n-1) ? {`DW_index_width{1'b0}} :  token_cs + one_iw;
	token_ns    = next_token_ns_tmp[`DW_index_width-1:0];
        grant_ns    = {n{1'b0}};
        grant_indxn = {`DW_index_width{1'b0}};
      end else begin // all masked_reqers go to zero....
        token_ns    = token_cs; 
        grant_ns    = {n{1'b0}};
        grant_indxn = {`DW_index_width{1'b0}};
      end
    end else begin // not enabled
      grant_ns    = {n{1'b0}};
      token_ns    = {`DW_index_width{1'b0}};
      grant_indxn = {`DW_index_width{1'b0}};
    end
  end 
generate
  if (output_mode == 1) begin : GEN_OM_EQ_1
    assign granted     = granted_r;
    assign grant       = grant_cs;
    assign grant_index = grant_indxr;
  end else begin : GEN_OM_NE_1
    assign granted     = grant_ro;
    assign grant       = grant_ns;
    assign grant_index = grant_indxn;
  end
endgenerate
endmodule
