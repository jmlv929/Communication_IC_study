/////////////

////////////////////////////////////////////////////////////////////////////////
//
// ABSTRACT: Pipelined Multiply and Accumulate Synthesis Model
//
//           This receives two operands that get multiplied and 
//           accumulated.  The operation is configurable to be
//           pipelined.  Also, includes pipeline management.
//
//              Parameters      Valid Values   Description
//              ==========      ============   ===========
//              a_width           1 to 1024    default: 8
//                                             Width of 'a' input
//
//              b_width           1 to 1024    default: 8
//                                             Width of 'a' input
//
//              acc_width         2 to 2048    default: 16
//                                             Width of 'a' input
//                                               Must be >= (a_width + b_width)
//
//              tc                  0 or 1     default: 0
//                                             Twos complement control
//                                               0 => unsigned
//                                               1 => signed
//
//              pipe_reg            0 to 7     default: 0
//                                             Pipeline register stages
//                                               0 => no pipeline register stages inserted
//                                               1 => pipeline stage0 inserted
//                                               2 => pipeline stage1 inserted
//                                               3 => pipeline stages 0 and 1 inserted
//                                               4 => pipeline stage2 pipeline inserted
//                                               5 => pipeline stages 0 and 2 pipeline inserted
//                                               6 => pipeline stages 1 and 2 inserted
//                                               7 => pipeline stages 0, 1, and 2 inserted
//
//              id_width          1 to 1024    default: 1
//                                             Width of 'launch_id' and 'arrive_id' ports
//
//              no_pm               0 or 1     default: 0
//                                             Pipeline management included control
//                                               0 => DW_pipe_mgr connected to pipeline
//                                               1 => DW_pipe_mgr bypassed
//
//              op_iso_mode       0 to 4       default: 0
//                                             Type of operand isolation
//                                               0 => Follow intent defined by Power Compiler user setting
//                                               1 => no operand isolation
//                                               2 => 'and' gate isolaton
//                                               3 => 'or' gate isolation
//                                               4 => preferred isolation style: 'and' gate

//
//              
//              Input Ports:    Size           Description
//              ===========     ====           ===========
//              clk             1 bit          Input Clock
//              rst_n           1 bit          Active Low Async. Reset
//		init_n          1 bit          Active Low Sync. Reset
//              clr_acc_n       1 bit          Actvie Low Clear accumulate results
//              a               a_width bits   Multiplier
//              b               b_width bits   Multiplicand
//              launch          1 bit          Start a multiply and accumulate with a and b
//              launch_id       id_width bits  Identifier associated with 'launch' assertion
//              accept_n        1 bit          Downstream logic ready to use 'acc' result (active low)
//
//              Output Ports    Size           Description
//              ============    ====           ===========
//              acc             acc_width bits Multiply and accumulate result
//              arrive          1 bit          Valid multiply and accumulate result
//              arrive_id       id_width bits  launch_id from originating launch that produced acc result
//              pipe_full       1 bit          Upstream notification that pipeline is full
//              pipe_ovf        1 bit          Status Flag indicating pipe overflow
//              push_out_n      1 bit          Active Low Output used with FIFO (optional)
//              pipe_census     3 bits         Output bus indicating the number of pipe stages currently occupied
//
//
// MODIFIED: 
//              DLL   1-10-07  Converted looping variables from global to local
//
//		RJK  10-22-07  Merged pipe manager into piped_mac
//
//              DLL   6-27-08  Enhanced abstract comments, added 'op_iso_mode' parameter,
//                             and removed 'multp_stages' parameter and associated unused code
//
//
////////////////////////////////////////////////////////////////////////////////

module DW_piped_mac (
    clk,
    rst_n,
    init_n,
    clr_acc_n,
    a,
    b,
    acc,

    launch,
    launch_id,
    pipe_full,
    pipe_ovf,

    accept_n,
    arrive,
    arrive_id,
    push_out_n,
    pipe_census
    // Embedded dc_shell script
    // _model_constraint_1
    // set_attribute current_design "enable_dp_opt" "TRUE" -type "boolean" -quiet
    // if ( find( "cell", "*stage0*" ) ) {
    //   set_dont_retime find("cell", "*stage0*") "true"
    // }
    // if ( find( "cell", "*stage2*" ) ) {
    //   set_dont_retime find("cell", "*stage2*") "true"
    // }
    );

parameter a_width      = 8;  // RANGE 1 to 1024
parameter b_width      = 8;  // RANGE 1 to 1024
parameter acc_width    = 16; // RANGE 2 to 2048
parameter tc           = 0;  // RANGE 0 to 1
parameter pipe_reg     = 0;  // RANGE 0 to 7
parameter id_width     = 1;  // RANGE 1 to 1024
parameter no_pm        = 0;  // RANGE 0 to 1
parameter op_iso_mode  = 0;  // RANGE 0 to 4


`define multp_width     (a_width+b_width+2)
`define DW_max_stages   ((pipe_reg==0)?1:((pipe_reg==7)?4:(((pipe_reg==1)||(pipe_reg==2)||(pipe_reg==4))?2:3)))


input                       clk;        // Input Clock
input                       rst_n;      // Active Low Async. Reset
input                       init_n;     // Active Low Sync. Reset
input                       clr_acc_n;  // Active Low Clear accumulate results
input  [a_width-1:0]        a;          // Multiplier
input  [b_width-1:0]        b;          // Multiplicand
output [acc_width-1:0]      acc;        // Multiply and accumulate result

input                       launch;     // Start a multiply and accumulate with a and b
input  [id_width-1:0]       launch_id;  // Identifier associated with 'launch' assertion
output                      pipe_full;  // Upstream notification that pipeline is full
output                      pipe_ovf;

input                       accept_n;   // Downstream logic ready to use 'acc' result - active low
output                      arrive;     // Valid multiply and accumulate result
output [id_width-1:0]       arrive_id;  // launch_id from originating launch that produced out result
output                      push_out_n;
output [2:0]                pipe_census;


wire                        launch_pm;     // Start a multiply and accumulate with a and b
wire   [id_width-1:0]       launch_id_pm;  // Identifier associated with 'launch' assertion
wire                        pipe_full_pm;  // Upstream notification that pipeline is full
reg                         pipe_ovf_pm;

wire                        accept_n_pm;   // pipe mgr downstream logic ready to use 'acc' result - active low
wire                        arrive_pm;     // pipe mgr valid multiply and accumulate result
wire   [id_width-1:0]       arrive_id_pm;  // pipe mgr launch_id from originating launch that produced out result
wire                        push_out_n_pm;

wire  [`DW_max_stages-1:0]  pipe_en_bus;
wire  [`DW_max_stages-1:0]  pipe_en_bus_pm;

reg   [2:0]		    pipe_census_pm;
wire  [2:0]		    pipe_census_int;
wire  [2:0]                 pipe_census;

reg                         en0;
reg                         en1;
reg                         en_acc;
reg                         en2;

wire  [a_width-1:0]         a_int;
wire  [a_width-1:0]         next_a_stage0;
reg   [a_width-1:0]         a_stage0;

wire  [b_width-1:0]         b_int;
wire  [b_width-1:0]         next_b_stage0;
reg   [b_width-1:0]         b_stage0;

wire                        clr_acc_n_int0;
wire                        next_clr_acc_n_stage0;
reg                         clr_acc_n_stage0;

wire  [`multp_width-1:0]    multp_out0;
wire  [`multp_width-1:0]    multp_out1;

wire  [`multp_width-1:0]    next_multp_out0_stage1;
reg   [`multp_width-1:0]    multp_out0_stage1;
wire  [`multp_width-1:0]    next_multp_out1_stage1;
reg   [`multp_width-1:0]    multp_out1_stage1;

wire  [`multp_width-1:0]    multp_out0_selected;
wire  [`multp_width-1:0]    multp_out1_selected;

reg   [acc_width-1:0]       multp_out0_sized;
reg   [acc_width-1:0]       multp_out1_sized;

wire                        clr_acc_n_int1;
wire                        next_clr_acc_n_stage1;
reg                         clr_acc_n_stage1;

wire  [acc_width-1:0]       acc0_reg_gated;
wire  [acc_width-1:0]       acc1_reg_gated;

wire  [(acc_width*4)-1:0]   tree_input;

wire  [acc_width-1:0]       tree_OUT0;
wire  [acc_width-1:0]       tree_OUT1;

wire  [acc_width-1:0]       next_acc0_reg;
reg   [acc_width-1:0]       acc0_reg;
wire  [acc_width-1:0]       next_acc1_reg;
reg   [acc_width-1:0]       acc1_reg;

wire  [acc_width-1:0]       add_stage2_pre;
wire  [acc_width-1:0]       next_add_stage2;
reg   [acc_width-1:0]       add_stage2;

wire  [acc_width-1:0]       acc_int;

wire  [acc_width-1:0]       acc_zeroes;
wire  [acc_width-1:0]       acc_ones;

wire  [`multp_width-1:0]    multp_ones;

reg  [2:0]		      next_pipe_census;
reg  [`DW_max_stages-1:0]     dtsr;
reg  [`DW_max_stages-1:0]     next_dtsr;
reg  [`DW_max_stages-1:0]     hold_en;
reg  [`DW_max_stages-1:0]     pipe_en_bus_int;
reg  [id_width-1:0]	      idsr [`DW_max_stages-1:0];
reg  [(`DW_max_stages*3)-1:0] stgcnt;


 assign acc_zeroes = {acc_width{1'b0}};
 assign acc_ones   = {acc_width{1'b1}};

 assign multp_ones = {`multp_width{1'b1}};



  always @ (dtsr or accept_n_pm or hold_en) begin : PROC_mk_hold_en
    integer j;

    for (j=0 ; j<`DW_max_stages ; j=j+1) begin
      if (j == 0)
        hold_en[`DW_max_stages-1] = accept_n_pm & dtsr[`DW_max_stages-1];
      else
        hold_en[`DW_max_stages-1-j] = hold_en[`DW_max_stages-j] & dtsr[`DW_max_stages-1-j];
    end // for (j
  end
  
  always @ (hold_en or dtsr or launch_pm) begin : PROC_mk_next_dtsr
    integer k;

    for (k=0 ; k<`DW_max_stages ; k=k+1) begin
      if (k==0) begin
        next_dtsr[0] = launch_pm | hold_en[0];
	pipe_en_bus_int[0] = launch_pm & ~hold_en[0];
      end else begin
        next_dtsr[k] = dtsr[k-1] | hold_en[k];
	pipe_en_bus_int[k] = dtsr[k-1] & ~hold_en[k];
      end
    end // for (k
  end

  assign pipe_en_bus_pm = pipe_en_bus_int;
  assign arrive_pm = dtsr[`DW_max_stages-1];
  assign arrive_id_pm = idsr[`DW_max_stages-1];
  assign pipe_full_pm = hold_en[0];
  assign push_out_n_pm = ~(dtsr[`DW_max_stages-1] & ~accept_n_pm);


  always @ (next_dtsr) begin : PROC_mk_stgcnt
    integer i, j, k;

    k = 0;

    for (i=0 ; i < `DW_max_stages ; i=i+1) begin
      stgcnt[k] = next_dtsr[i];

      for (j=1 ; j < 3 ; j=j+1)
	stgcnt[k+j] = 1'b0;

      k = k + 3;
    end
  end


  always @ (stgcnt) begin : PROC_mk_census
    integer l, m, n;
    reg [2:0] temp_census, temp_adder;
    reg [`DW_max_stages*3-1:0] temp_select;

    temp_census = 0;
    m = 0;

    for (n=0 ; n < `DW_max_stages ; n=n+1) begin
      temp_select = stgcnt >> m;
      temp_adder = temp_select[2 : 0];
      temp_census = temp_census + temp_adder;
      m = m + 3;
    end

    next_pipe_census = temp_census;
  end

       

// Bypass around DW_pipe_mgr inputs/outputs if parameter "no_pm" is 1
assign launch_pm       = (no_pm == 1'b1) ? 1'b1 : launch;
assign launch_id_pm    = (no_pm == 1'b1) ? {id_width{1'b0}} : launch_id;
assign pipe_full       = (no_pm == 1'b1) ? 1'b0 : pipe_full_pm;
assign pipe_ovf        = (no_pm == 1'b1) ? 1'b0 : pipe_ovf_pm;
assign pipe_en_bus     = (no_pm == 1'b1) ? {`DW_max_stages{1'b1}} : pipe_en_bus_pm;

assign accept_n_pm     = (no_pm == 1'b1) ? 1'b0 : accept_n;
assign arrive          = (no_pm == 1'b1) ? 1'b1 : arrive_pm;
assign arrive_id       = (no_pm == 1'b1) ? {id_width{1'b0}} : arrive_id_pm;
assign push_out_n      = (no_pm == 1'b1) ? 1'b0 : push_out_n_pm;
assign pipe_census_int = (no_pm == 1'b1) ? 3'b000 : pipe_census_pm;


  always @(pipe_en_bus) begin : PROC_PIPE_STAGES
    integer  idx;

    case (pipe_reg)
      3'b000: begin
                en_acc = pipe_en_bus[0];
              end  // 3'b000
      3'b001: begin
                for (idx = 0; idx < `DW_max_stages; idx = idx + 1) begin
                  if (idx == 0)
                    en0 = pipe_en_bus[idx];
                  else
                    en_acc = pipe_en_bus[idx];
                end  // for
              end  // 3'b001
      3'b010: begin
                for (idx = 0; idx < `DW_max_stages; idx = idx + 1) begin
                  if (idx < `DW_max_stages-1)
                    en1 = pipe_en_bus[idx];
                  else
                    en_acc = pipe_en_bus[idx];
                end  // for
              end  // 3'b010
      3'b011: begin
                for (idx = 0; idx < `DW_max_stages; idx = idx + 1) begin
                  if (idx == 0)
                    en0 = pipe_en_bus[idx];
                  else if (idx < `DW_max_stages-1)
                    en1 = pipe_en_bus[idx];
                  else
                    en_acc = pipe_en_bus[idx];
                end  // for
              end  // 3'b011
      3'b100: begin
                for (idx = 0; idx < `DW_max_stages; idx = idx + 1) begin
                  if (idx < `DW_max_stages-1)
                    en_acc = pipe_en_bus[idx];
                  else
                    en2 = pipe_en_bus[idx];
                end  // for
              end  // 3'b100
      3'b101: begin
                for (idx = 0; idx < `DW_max_stages; idx = idx + 1) begin
                  if (idx == 0)
                    en0 = pipe_en_bus[idx];
                  else if (idx < `DW_max_stages-1)
                    en_acc = pipe_en_bus[idx];
                  else
                    en2 = pipe_en_bus[idx];
                end  // for
              end  // 3'b101
      3'b110: begin
                for (idx = 0; idx < `DW_max_stages; idx = idx + 1) begin
                  if (idx < `DW_max_stages-2)
                    en1 = pipe_en_bus[idx];
                  else if (idx < `DW_max_stages-1)
                    en_acc = pipe_en_bus[idx];
                  else
                    en2 = pipe_en_bus[idx];
                end  // for
              end  // 3'b110
      3'b111: begin
                for (idx = 0; idx < `DW_max_stages; idx = idx + 1) begin
                  if (idx == 0)
                    en0 = pipe_en_bus[idx];
                  else if (idx < `DW_max_stages-2)
                    en1 = pipe_en_bus[idx];
                  else if (idx < `DW_max_stages-1)
                    en_acc = pipe_en_bus[idx];
                  else
                    en2 = pipe_en_bus[idx];
                end  // for
              end  // 3'b111
    endcase
  end


  assign next_a_stage0         = (en0 == 1'b1) ? a : a_stage0;
  assign next_b_stage0         = (en0 == 1'b1) ? b : b_stage0;
  assign next_clr_acc_n_stage0 = (en0 == 1'b1) ? clr_acc_n : clr_acc_n_stage0;

  assign a_int          = (pipe_reg[0] == 1'b1) ? a_stage0 : a;
  assign b_int          = (pipe_reg[0] == 1'b1) ? b_stage0 : b;
  assign clr_acc_n_int0 = (pipe_reg[0] == 1'b1) ? clr_acc_n_stage0 : clr_acc_n;


DW02_multp #(a_width, b_width, a_width + b_width + 2) U_MULTP (
  	.a(a_int),
	.b(b_int),
	.tc(tc[0]),
	.out0(multp_out0),
	.out1(multp_out1)
        );

  assign next_multp_out0_stage1 = (en1 == 1'b1) ? multp_out0 : multp_out0_stage1;
  assign next_multp_out1_stage1 = (en1 == 1'b1) ? multp_out1 : multp_out1_stage1;

  assign multp_out0_selected = (pipe_reg[1] == 1) ? multp_out0_stage1 :  multp_out0; 
  assign multp_out1_selected = (pipe_reg[1] == 1) ? multp_out1_stage1 :  multp_out1; 

  always @(multp_out0_selected or multp_out1_selected) begin : PROC_MULTP_OUT_SIZED
    integer  aidx;

    for (aidx = 0; aidx < acc_width; aidx = aidx + 1) begin
      if (aidx <= (a_width+b_width+1)) begin
	multp_out0_sized[aidx] = multp_out0_selected[aidx];
	multp_out1_sized[aidx] = multp_out1_selected[aidx];
      end else begin
	multp_out0_sized[aidx] = 1'b0;
	multp_out1_sized[aidx] = multp_out1_selected[(a_width+b_width+1)];
      end
    end  // for
  end  // always

  assign next_clr_acc_n_stage1 = (en1 == 1'b1) ? clr_acc_n_int0 : clr_acc_n_stage1;
  assign clr_acc_n_int1 = (pipe_reg[1] == 1'b1) ? clr_acc_n_stage1 : clr_acc_n_int0;

  assign acc0_reg_gated = {acc_width{clr_acc_n_int1}} & acc0_reg;
  assign acc1_reg_gated = {acc_width{clr_acc_n_int1}} & acc1_reg;

  assign tree_input   = {multp_out1_sized, multp_out0_sized, acc1_reg_gated, acc0_reg_gated};
						 

DW02_tree #(4, acc_width) U_TREE (
        .INPUT(tree_input),
        .OUT0(tree_OUT0),
        .OUT1(tree_OUT1)
        );

  assign {next_acc1_reg, next_acc0_reg} = (en_acc == 1'b1) ? {tree_OUT1, tree_OUT0} : {acc1_reg, acc0_reg};

  assign add_stage2_pre  = acc0_reg + acc1_reg;
  assign next_add_stage2 = (en2 == 1'b1) ? add_stage2_pre : add_stage2;
  assign acc_int         = (pipe_reg[2] == 1'b1) ? add_stage2 : add_stage2_pre;



  always @ (posedge clk or negedge rst_n) begin : PROC_posedge_s_registers
    if (rst_n == 1'b0) begin
      a_stage0             <= {a_width{1'b0}};
      b_stage0             <= {b_width{1'b0}};
      clr_acc_n_stage0     <= 1'b0;
      multp_out0_stage1    <= {`multp_width{1'b0}};
      multp_out1_stage1    <= {`multp_width{1'b0}};
      clr_acc_n_stage1     <= 1'b0;
      acc0_reg             <= {acc_width{1'b0}};
      acc1_reg             <= {acc_width{1'b0}};
      add_stage2           <= {acc_width{1'b0}};
    end else if (init_n == 1'b0) begin
      a_stage0             <= {a_width{1'b0}};
      b_stage0             <= {b_width{1'b0}};
      clr_acc_n_stage0     <= 1'b0;
      multp_out0_stage1    <= {`multp_width{1'b0}};
      multp_out1_stage1    <= {`multp_width{1'b0}};
      clr_acc_n_stage1     <= 1'b0;
      acc0_reg             <= {acc_width{1'b0}};
      acc1_reg             <= {acc_width{1'b0}};
      add_stage2           <= {acc_width{1'b0}};
    end else begin
      a_stage0             <= next_a_stage0;
      b_stage0             <= next_b_stage0;
      clr_acc_n_stage0     <= next_clr_acc_n_stage0;
      multp_out0_stage1    <= next_multp_out0_stage1;
      multp_out1_stage1    <= next_multp_out1_stage1;
      clr_acc_n_stage1     <= next_clr_acc_n_stage1;
      acc0_reg             <= next_acc0_reg;
      acc1_reg             <= next_acc1_reg;
      add_stage2           <= next_add_stage2;
    end
  end

  always @ (posedge clk or negedge rst_n) begin : PROC_registers
    integer  i;
    if (rst_n == 1'b0) begin
      dtsr <= {`DW_max_stages{1'b0}};
      pipe_ovf_pm <= 1'b0;
      pipe_census_pm <= 0;
      for (i=0 ; i < `DW_max_stages ; i=i+1) begin
	idsr[i] <= {id_width{1'b0}};
      end
    end else begin
      dtsr <= (init_n == 1'b1)? next_dtsr : 0;
      pipe_ovf_pm <= hold_en[0] & launch_pm;
      pipe_census_pm <= (init_n == 1'b1)? next_pipe_census : 0;
      for (i=0 ; i < `DW_max_stages ; i=i+1) begin
        if (i == 0) begin
	  if ((pipe_en_bus_pm[0] | ~init_n) == 1'b1)
	    idsr[0] <= launch_id_pm & {id_width{init_n}};
	end else begin
	  if ((pipe_en_bus_pm[i] | ~init_n) == 1'b1)
	    idsr[i] <= idsr[i-1] & {id_width{init_n}};
	end
      end
    end
  end

  assign acc          = acc_int;
  assign pipe_census  = pipe_census_int;

`undef DW_max_stages
`undef multp_width

endmodule
