//TAP FSM implementation
module tap_FSM #(parameter sync_mode = 1)(
input   tck,
input   trst_n,
input   tms,
input   tdi,
output  byp_out,
output  clockDR, updateDR, clockIR, updateIR, tdo_en, reset_n, shiftDR,
output  shiftIR, selectIR, sync_capture_en, sync_update_dr, flag,
output [15:0] tap_state
);
//Inter signal declaration
reg [15:0] state;
reg [15:0] next_s;
reg scan_out_a, scan_out_s, updateIR_a;

localparam TEST_LOGIC_RESET = 16'h0001, RUN_TEST_IDLE = 16'h0002, SELECT_DR_SCAN = 16'H0004,
  CAPTURE_DR= 16'h0008, SHIFT_DR = 16'h0010, EXIT1_DR = 16'h0020,PAUSE_DR = 16'h0040,
  EXIT2_DR  = 16'h0080, UPDATE_DR= 16'h0100, SELECT_IR_SCAN = 16'h0200,
  CAPTURE_IR= 16'h0400, SHIFT_IR = 16'h0800, EXIT1_IR = 16'h1000,
  PAUSE_IR  = 16'h2000, EXIT2_IR = 16'h4000, UPDATE_IR= 16'h8000;

wire flag = state[10] || state[11];
wire updateIR_s = state == UPDATE_IR;
wire updateIR   = sync_mode ? updateIR_s : updateIR_a;
assign tap_state= state;

always @(posedge tck or negedge trst_n)
  if ( !trst_n )
    state<=TEST_LOGIC_RESET;
  else
    state<=next_s;

always @(*)
  case(state)
    TEST_LOGIC_RESET: if(tms)
                        next_s=TEST_LOGIC_RESET;
                      else
                        next_s=RUN_TEST_IDLE;
    RUN_TEST_IDLE: if( tms )
                     next_s=SELECT_DR_SCAN;
                   else
                     next_s=RUN_TEST_IDLE;
    SELECT_DR_SCAN: if(tms)
                      next_s=SELECT_IR_SCAN;
                    else
                      next_s=CAPTURE_DR;
    CAPTURE_DR: if(tms)
                  next_s=EXIT1_DR;
                else
                  next_s=SHIFT_DR;
    SHIFT_DR: if(tms)
                next_s=EXIT1_DR;
              else
                next_s=SHIFT_DR;
    EXIT1_DR: if(tms)
                next_s=UPDATE_DR;
              else
                next_s=PAUSE_DR;
    PAUSE_DR: if(tms)
                next_s=EXIT2_DR;
              else
                next_s=PAUSE_DR;
    EXIT2_DR: if(tms)
                next_s=UPDATE_DR;
              else
                next_s=SHIFT_DR;
    UPDATE_DR: if(tms)
                next_s=SELECT_DR_SCAN;
              else
                next_s=RUN_TEST_IDLE;
    SELECT_IR_SCAN:if(tms)
                     next_s=TEST_LOGIC_RESET;
                   else
                     next_s=CAPTURE_IR;
    CAPTURE_IR: if(tms)
                  next_s=EXIT1_IR;
                else
                  next_s=SHIFT_IR;
    SHIFT_IR: if(tms)
                next_s=EXIT1_IR;
              else
                next_s=SHIFT_IR;
    EXIT1_IR: if(tms)
                next_s=UPDATE_IR;
              else
                next_s=PAUSE_IR;
    PAUSE_IR: if(tms)
                next_s=EXIT2_IR;
              else
                next_s=PAUSE_IR;
    EXIT2_IR: if(tms)
                next_s=UPDATE_IR;
              else
                next_s=SHIFT_IR;
    UPDATE_IR: if(tms)
                next_s=SELECT_DR_SCAN;
              else
                next_s=RUN_TEST_IDLE;
  endcase

//FSM outputs
reg  clockDR, updateDR, clockIR, tdo_en, rst_n, shiftDR, shiftIR;
//ClockDR/ClockIR - posedge occurs at the posedge of tck
//updateDR/updateIR - posedge occurs at the negedge of tck
always @( tck or state )begin
    if ( !tck && ( state == CAPTURE_DR || state == SHIFT_DR ))
      clockDR = 0;
    else
      clockDR = 1;

    if ( !tck && ( state == UPDATE_DR ))
      updateDR = 1;
    else
      updateDR = 0;

    if ( !tck && ( state == CAPTURE_IR || state == SHIFT_IR ))
      clockIR = 0;
    else
      clockIR = 1;

    if ( !tck && ( state == UPDATE_IR ))
      updateIR_a = 1;
    else
      updateIR_a = 0;
  end

always  @( negedge tck )
  if ( state == SHIFT_IR || state == SHIFT_DR )
    tdo_en <= 1;
  else
    tdo_en <= 0;

always  @( negedge tck ) 
  if ( state == TEST_LOGIC_RESET )
    rst_n <= 0;
  else
    rst_n <= 1;

always @(negedge tck or negedge trst_n)
  if ( !trst_n )
    shiftDR <= 0;
  else if ( state == SHIFT_DR )
    shiftDR <= 1;
  else
    shiftDR <= 0;

always @(negedge tck or negedge trst_n)
  if ( !trst_n )
    shiftIR <= 0;
  else if ( state == SHIFT_IR )
    shiftIR <= 1;
  else
    shiftIR <= 0;

assign reset_n = rst_n & trst_n;
assign selectIR = state == SHIFT_IR;
assign sync_capture_en = ~(shiftDR | (state == CAPTURE_DR) | (state == SHIFT_DR));
assign sync_update_dr = state == UPDATE_DR;

always @( posedge clockDR )
  scan_out_a <= shiftDR & tdi & ~(state == CAPTURE_DR);

wire nxt_st_3 = (state == SELECT_DR_SCAN) & ~tms;
wire nxt_st_4 = ((state == CAPTURE_DR) & ~tms) || ( state == SHIFT_DR & ~tms);

reg sel;
always @(posedge tck or negedge trst_n)
  if(!trst_n )
    sel <= 0;
  else
    sel <= ~(nxt_st_3 | nxt_st_4);

wire scan_out = sel ? scan_out_s : shiftDR & tdi;
always @(posedge tck )
  scan_out_s <= scan_out & ~(state == CAPTURE_DR);

assign byp_out = sync_mode ? scan_out_s : scan_out_a;

endmodule
