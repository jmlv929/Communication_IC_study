
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
// ABSTRACT :
//	Arbiter based on Static priority scheme.
//      Parameters      Valid Values    Description
//      ==========      =========       ===========
//      n               {2 to 32}       Number of arbiter clients
//      park_mode       {0 to 1}        Enable/Disable parking of grant
//      park_index      {0 to 31}       Park the grant to default
//      output_mode     {0 to 1}        Enable/disable registered outputs   
//      
//      Input Ports   Size       Description
//      ===========   ====       ============
//      clk             1        Input clock
//      rst_n           1        Active low reset
//      init_n          1        Active low synchronous reset
//      enable          1        Active high enable
//      request         n        Input requests from clients
//      lock            n        lock the grant to the current request
//      mask            n        Input to mask specific client request
//      locked          1        Flag to indicate locked condition
//      parked          1        Flag to indicate that there are no
//                               requesting clients and the the grant
//                               of resources has defauled to park_index
//      granted         1        Flag to indicate that arbiter has
//                               granted the resource to one of the
//                               requesting clients
//      grant           n        Grant output: one hot select line
//                               indicating grantee 
//      grant_index     log2(n)  Index of the current grant
//
// Modification history:
//                                      
//  RJK  10/07/2011  Added full labeling of all regions of generate
//                   statement code
//
//	RJK 10/0/10  STAR 9000423611 - Fixed use of lock input to
//			allow multiple lock requests
//-----------------------------------------------------------------------------
////////////////////////////////////////////////////////////////////////////////

module DW_arb_sp (
           clk,
           rst_n,
           init_n,
           enable,
           request,
           lock,
           mask,
           parked,
           locked,
           granted,
           grant,
           grant_index
    );
    
  parameter n                = 4; // RANGE 2 to 32
  parameter park_mode        = 1; // RANGE 0 or 1
  parameter park_index       = 0; // RANGE 0 to (n - 1)
  parameter output_mode      = 1; // RANGE 0 or 1
`define DW_index_width ((n>16)?((n>64)?((n>128)?8:7):((n>32)?6:5)):((n>4)?((n>8)?4:3):((n>2)?2:1)))


  input				clk;	 // clock input
  input				rst_n;	 // active low asynchronous reset
  input				init_n;	 // active low synchronous reset
  input				enable;	 // active high enable
  input  [n-1: 0]		request; // client request bus
  input  [n-1: 0]		lock;	 // client lock bus
  input  [n-1: 0]		mask;	 // client mask bus

  output			parked;	 // arbiter parked status flag
  output			granted; // arbiter granted status flag
  output			locked;	 // arbeter locked status bus
  output [n-1: 0]		grant;	 // one-hot granted client bus
  output [`DW_index_width-1: 0]	grant_index; //ndex of current granted client 

localparam [0:0]		parked_mode = park_mode;
localparam [`DW_index_width-1:0]	idle_index = (park_mode == 1) ? park_index : -1;
localparam [n-1:0]		idle_grant = (park_mode == 1) ? 1 << park_index : 0;

reg  [`DW_index_width-1 : 0] grant_index_int, grant_index_next;
reg  [n-1 : 0]           grant_next, grant_int;


reg            parked_next, parked_int;
reg            granted_next, granted_int;
reg            locked_next, locked_int;

wire [n-1 : 0] mreq;
   
  assign             mreq = request & ~mask;

always @ (mreq or lock or grant_index_int or grant_int 
          or parked_int or granted_int ) begin : MASKED_REQ_COMBO_PROC
   integer   index;
   if( (|(lock & grant_int) & granted_int) != 1'b0) begin
     locked_next      = 1'b1;
     grant_index_next = grant_index_int;
     grant_next       = grant_int;
     parked_next      = parked_int;
     granted_next     = granted_int;
   end else begin
      grant_index_next = idle_index;
      grant_next       = idle_grant;
      parked_next      = parked_mode;
      granted_next     = 1'b0;
      locked_next      = 1'b0;
      for(index = 0; index < n; index = index +1) begin
        if (mreq[n - 1 - index] == 1'b1) begin
          grant_next       = 1'b1 << n - 1 - index;
          grant_index_next = n -1 - index;
          parked_next      = 1'b0;
          granted_next     = 1'b1;
        end
      end
   end
 end

  always @(posedge clk or negedge rst_n) begin : register
    if (rst_n == 1'b0) begin
      grant_index_int     <= idle_index;
      parked_int          <= 1'b0;
      granted_int         <= 1'b0;
      locked_int          <= 1'b0;
      grant_int           <= idle_grant;
    end else if (init_n == 1'b0) begin
      grant_index_int     <= idle_index;
      parked_int          <= 1'b0;
      granted_int         <= 1'b0;
      locked_int          <= 1'b0;
      grant_int           <= idle_grant;
    end else if(enable) begin
      grant_index_int     <= grant_index_next;
      parked_int          <= parked_next;
      granted_int         <= granted_next;
      locked_int          <= locked_next;
      grant_int           <= grant_next;
    end
  end

  generate
    if (output_mode == 0) begin : GEN_OM_EQ_0
      assign grant	 = (init_n==1'b0)? idle_grant : grant_next;
      assign grant_index = (init_n==1'b0)? idle_index : grant_index_next;
      assign granted	 = granted_next & init_n;
      assign locked	 = locked_next & init_n;
    end else begin : GET_OM_NE_0
      assign grant	 = grant_int;
      assign grant_index = grant_index_int;
      assign granted	 = granted_int;
      assign locked	 = locked_int;
    end
  endgenerate

  generate
    if (park_mode == 0) begin : GEN_PM_EQ_0
      assign parked = 1'b0;
    end else if (output_mode == 0) begin : GEN_PM_NE_0_OM_EQ_0
      assign parked	= parked_next & init_n;
    end else begin : GEN_PM_NE_0_OM_NE_0
      assign parked	= parked_int;
    end
  endgenerate

endmodule
