
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
//
// ABSTRACT:  Arbiter with two-level priority scheme
//            - first level: dynamic priority scheme
//            - second level: Fair-Among-Equal priority scheme
//
// ABSTRACT:  Synchronous with Static Flags
//           programmable almost empty and almost full flags
//
//      Parameters:     Valid Values
//      ==========      ============
//      n               [ 2 to 32 ] Number of arbiter clients
//      p_width         [ 1 to 5 ]  Width of the priority vector of each client
//      park_mode       [ 0 to 1 ]  0 = no parking supported
//                                  1 = enables parking when no clients are requesting
//      park_index      [ 0 to 4 ]  High index for the range of n
//      output_mode     [ 0 to 1 ]  0 output is NOT registered
//         
//      Input Ports:    Size             Description
//      ===========     ===============  ===========
//      clk             1 bit              Input clock
//      rst_n           1 bit              Active low Asynchronous Reset
//      init_n          1 bit              Active low Synchronous Reset
//      enable          1 bit              When 0 frezzes outputs to current state
//      request         n bits             Request from clients
//      prior           p_width * n bits   Priority vector from the clients
//      lock            n bits             Active high to lock the current grant
//      mask            n bits             Setting mask(i) high will disable request(i)
//      enable          1 bit              Active high allows arbitration to continue
//                                                 low holds the current arbritation
//  
//      Output Ports:    Size             Description
//      ===========     ===============  ===========
//      parked          1 bit              Indicates grant is issued to client indicated
//                                         in parameter park_index (while no requests are pending)
//      granted         1 bit              Indication that a grant has been issued to a request
//      locked          1 bit              Indicates arbiter is locked by client
//      grant           n bits             Grant output
//      grant_index    ceil(log2(n)) bits  Index of the requesting client either parked or granted
//
// Modifications:
//                                      
//  RJK  10/07/2011  Added full labeling of all regions of generate
//                   statement code
//
// 10/13/2010 RJK Corrected "lock from park state" issue
//
//  7/14/2011 RJK Updates for Leda checking
//
////////////////////////////////////////////////////////////////////////////////


  module DW_arb_2t (
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

                          
  parameter n           = 4;  // RANGE 2 TO 32
  parameter p_width     = 2;  // RANGE 1 TO 5
  parameter park_mode   = 1;  // RANGE 0 OR 1
  parameter park_index  = 0;  // RANGE 0 TO 31
  parameter output_mode = 1;  // RANGE 0 OR 1
`define DW_index_width ((n>16)?((n>64)?((n>128)?8:7):((n>32)?6:5)):((n>4)?((n>8)?4:3):((n>2)?2:1)))


  input				clk;	 // Clock input
  input				rst_n;	 // active low reset
  input				init_n;	 // active low reset
  input				enable;	 // active high register enable
  input  [n-1: 0]		request; // client request bus
  input  [p_width*n-1: 0]	prior;	 // client priority bus
  input  [n-1: 0]		lock;	 // client lock bus
  input  [n-1: 0]		mask;	 // client mask bus
  
  output			parked;	 // arbiter parked status flag
  output			granted; // arbiter granted status flag
  output			locked;	 // arbiter locked status flag
  output [n-1: 0]		grant;	 // one-hot client grant bus
  output [`DW_index_width-1: 0]	grant_index; //	 index of current granted client


  reg [1:0] current_state, next_state;
  wire [1:0] st_vec;

  wire   [n-1: 0] next_grant;
  wire   [`DW_index_width-1: 0] next_grant_index;
  wire   next_parked, next_granted, next_locked;

  reg    [n-1: 0] grant_int;
  reg    [`DW_index_width-1: 0] grant_index_int;
  reg    parked_int, granted_int, locked_int;

  reg    [`DW_index_width-1: 0] temp_prior, temp2_prior;

  wire   [(p_width+`DW_index_width+1)-1: 0] maxp1_priority;
  wire   [`DW_index_width-1: 0] max_prior;
  wire   [n-1: 0] masked_req;
  wire   active_request;

  reg [7:0] i1, j1, k1, l1, i2, j2, k2, i3, l3;


  reg    [(n*`DW_index_width)-1: 0] int_priority;

  reg    [(n*`DW_index_width)-1: 0] decr_prior;

  reg    [(n*(p_width+`DW_index_width+1))-1: 0] priority_vec;

  reg    [(n*(p_width+`DW_index_width+1))-1: 0] muxed_pri_vec;

  reg    [(n*`DW_index_width)-1: 0] next_prior;

  wire   [`DW_index_width-1: 0] current_index;
  wire [p_width+`DW_index_width:00] current_value;                 

  wire   [n-1: 0] temp_gnt;

  localparam [n-1 : 0] park_gnt = (park_mode == 0)? 0 : (1 << park_index);

  assign maxp1_priority = {p_width+`DW_index_width+1{1'b1}};
  assign max_prior = {`DW_index_width{1'b1}};

  assign masked_req = request & ~mask;

  assign active_request = |masked_req;

  assign next_locked = granted_int & |(grant_int & lock);

  assign next_granted = next_locked | active_request;

  assign next_parked = ~next_granted;

  always @(prior or int_priority)
  begin
    for (i1=0 ; i1<n ; i1=i1+1) begin
      for (j1=0 ; j1<(p_width+`DW_index_width+1) ; j1=j1+1) begin
        if (j1 == (p_width+`DW_index_width+1) - 1'b1) begin
          priority_vec[i1*(p_width+`DW_index_width+1)+j1] = 1'b0;
        end
        else if (j1 >= `DW_index_width) begin
          priority_vec[i1*(p_width+`DW_index_width+1)+j1] = prior[i1*p_width+(j1-(`DW_index_width))];
        end
        else begin
          priority_vec[i1*(p_width+`DW_index_width+1)+j1] = int_priority[i1*`DW_index_width+j1];
        end
      end
    end
  end

  always @(priority_vec or masked_req or maxp1_priority)
  begin
    for (k1=0 ; k1<n ; k1=k1+1) begin
      for (l1=0 ; l1<(p_width+`DW_index_width+1) ; l1=l1+1) begin
	muxed_pri_vec[k1*(p_width+`DW_index_width+1)+l1] = (masked_req[k1]) ?
          priority_vec[k1*(p_width+`DW_index_width+1)+l1]: maxp1_priority[l1];
      end
    end
  end

  always @(int_priority)
  begin
    for (i2=0 ; i2<n ; i2=i2+1) begin

      for (j2=0 ; j2<`DW_index_width ; j2=j2+1) begin
        temp_prior[j2] = int_priority[i2*`DW_index_width+j2];
      end

      temp2_prior = temp_prior - 1'b1;

      for (k2=0 ; k2<`DW_index_width ; k2=k2+1) begin
        decr_prior[i2*`DW_index_width+k2] = temp2_prior[k2];
      end

    end
  end


  assign st_vec = {next_parked, next_locked};

  always @(current_state or st_vec)
  begin
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

  always @(current_state or masked_req or next_grant or int_priority or
                    next_locked or decr_prior or max_prior)
  begin
    for (i3=0 ; i3<n ; i3=i3+1) begin
      for (l3=0 ; l3<`DW_index_width ; l3=l3+1) begin
        case (current_state)
        2'b00: begin
          if (masked_req[i3]) begin
            if (next_grant[i3]) begin
              next_prior[i3*`DW_index_width+l3] = max_prior[l3];
            end
            else begin
              next_prior[i3*`DW_index_width+l3] = decr_prior[i3*`DW_index_width+l3];
            end
          end
          else begin
            next_prior[i3*`DW_index_width+l3] = max_prior[l3];
          end
        end
        2'b01: begin
          if (next_locked) begin
            if (masked_req[i3]) begin
              if (next_grant[i3]) begin
                next_prior[i3*`DW_index_width+l3] = int_priority[i3*`DW_index_width+l3];
              end
              else begin
                next_prior[i3*`DW_index_width+l3] = decr_prior[i3*`DW_index_width+l3];
              end
            end
            else begin
              next_prior[i3*`DW_index_width+l3] = max_prior[l3];
            end
          end
          else begin
            if (masked_req[i3]) begin
              if (next_grant[i3]) begin
                next_prior[i3*`DW_index_width+l3] = max_prior[l3];
              end
              else begin
                next_prior[i3*`DW_index_width+l3] = decr_prior[i3*`DW_index_width+l3];
              end
            end
            else begin
              next_prior[i3*`DW_index_width+l3] = max_prior[l3];
            end
          end
        end
        default: begin
          if (next_locked) begin
            if (masked_req[i3] == 1'b0) begin
              next_prior[i3*`DW_index_width+l3] = max_prior[l3];
            end
            else begin
              next_prior[i3*`DW_index_width+l3] = int_priority[i3*`DW_index_width+l3];
            end
          end
          else begin
            if (masked_req[i3] == 1'b0) begin
              next_prior[i3*`DW_index_width+l3] = max_prior[l3];
            end
            else begin
              if (next_grant[i3]) begin
                next_prior[i3*`DW_index_width+l3] = max_prior[l3];
              end
              else begin
                next_prior[i3*`DW_index_width+l3] = decr_prior[i3*`DW_index_width+l3];
              end
            end
          end
        end
        endcase
      end
    end
  end

  DW_minmax #(p_width+`DW_index_width+1, n) U_minmax(
	.a(muxed_pri_vec),
	.tc(1'b0),
	.min_max(1'b0),
	.value(current_value),
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


  
  function [n-1:0] func_mux;
    input [n*4-1:0]	a;	// input bus
    input [2-1:0]  	sel;	// select
    reg   [n-1:0]	z;
    integer			i, j, k;
    begin
      z = {n {1'b0}};
      j = 0;
      k = 0;   // Temporary fix for a Leda issue
      for (i=0 ; i<4 ; i=i+1) begin
	if (i == sel) begin
	  for (k=0 ; k<n ; k=k+1) begin
	    z[k] = a[j + k];
	  end // for (k
	end // if
	j = j + n;
      end // for (i
      func_mux = z;
    end
  endfunction

  assign next_grant = func_mux( ({grant_int,park_gnt,grant_int,temp_gnt}), ({next_parked,next_locked}) );



  
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


  always @(posedge clk or negedge rst_n)
  begin
    if (rst_n == 1'b0) begin
      current_state       <= 2'b00;
      int_priority        <= {n*`DW_index_width{1'b1}};
      grant_index_int     <= {`DW_index_width{1'b1}};
      parked_int          <= 1'b0;
      granted_int         <= 1'b0;
      locked_int          <= 1'b0;
      grant_int           <= {n{1'b0}};
    end else if (init_n == 1'b0) begin
      current_state       <= 2'b00;
      int_priority        <= {n*`DW_index_width{1'b1}};
      grant_index_int     <= {`DW_index_width{1'b1}};
      parked_int          <= 1'b0;
      granted_int         <= 1'b0;
      locked_int          <= 1'b0;
      grant_int           <= {n{1'b0}};
    end else if (enable) begin
      current_state       <= next_state;
      int_priority        <= next_prior;
      grant_index_int     <= next_grant_index;
      parked_int          <= next_parked;
      granted_int         <= next_granted;
      locked_int          <= next_locked;
      grant_int           <= next_grant;
    end
  end

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
