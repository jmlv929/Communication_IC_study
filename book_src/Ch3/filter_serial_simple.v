// -------------------------------------------------------------
// HDL Code Generation Options:
//
// ResetType: Synchronous
// ResetInputPort: syn_rst
// TargetDirectory: E:\百度云同步盘\书籍\书稿\第三章
// AddOutputRegister: off
// Name: filter_serial
// RemoveResetFrom: ShiftRegister
// SerialPartition: 6
// TargetLanguage: Verilog
// TestBenchStimulus: impulse step ramp chirp noise 

// -------------------------------------------------------------
// HDL Implementation    : Fully Serial
// Multipliers           : 1
// Folding Factor        : 6
// -------------------------------------------------------------
// Filter Settings:
//
// Discrete-Time FIR Filter (real)
// -------------------------------
// Filter Structure  : Direct-Form FIR
// Filter Length     : 6
// Stable            : Yes
// Linear Phase      : Yes (Type 2)
// Arithmetic        : fixed
// Numerator         : s16,16 -> [-5.000000e-001 5.000000e-001)
// Input             : s16,15 -> [-1 1)
// Filter Internals  : Specify Precision
//   Output          : s16,15 -> [-1 1)
//   Product         : s31,31 -> [-5.000000e-001 5.000000e-001)
//   Accumulator     : s33,31 -> [-2 2)
//   Round Mode      : convergent
//   Overflow Mode   : wrap
// -------------------------------------------------------------
`timescale 1 ns / 1 ns

module filter_serial(
  input   clk, 
  input   clk_enable, 
  input   syn_rst, 
  input   signed [15:0] filter_in, //sfix16_En15
  output  signed [15:0] filter_out );//sfix16_En15

////////////////////////////////////////////////////////////////
//Module Architecture: filter_serial
////////////////////////////////////////////////////////////////
// Local Functions
// Type Definitions
// Constants
parameter signed [15:0] coeff1 = 16'b1110111010111001; //sfix16_En16
parameter signed [15:0] coeff2 = 16'b0100100010111111; //sfix16_En16
parameter signed [15:0] coeff3 = 16'b0111000110111010; //sfix16_En16
parameter signed [15:0] coeff4 = 16'b0111000110111010; //sfix16_En16
parameter signed [15:0] coeff5 = 16'b0100100010111111; //sfix16_En16
parameter signed [15:0] coeff6 = 16'b1110111010111001; //sfix16_En16

// Signals
reg  [2:0] cur_count;

always @ ( posedge clk)
  if (syn_rst == 1'b1)
    cur_count <= 3'b101;
  else if (clk_enable == 1'b1) begin
    if (cur_count == 3'b101)
      cur_count <= 3'b000;
    else 
      cur_count <= cur_count + 1;
  end

wire FIRST_SUM_STAGE= (cur_count == 3'b101 && clk_enable == 1'b1)? 1 : 0;
wire OUTPUT_STAGE = (cur_count == 3'b000 && clk_enable == 1'b1)? 1 : 0;

reg  signed [15:0] delay_pipeline [0:5] ; // sfix16_En15
always @( posedge clk)
  if (syn_rst == 1'b1) begin
    delay_pipeline[0] <= 0;
    delay_pipeline[1] <= 0;
    delay_pipeline[2] <= 0;
    delay_pipeline[3] <= 0;
    delay_pipeline[4] <= 0;
    delay_pipeline[5] <= 0;
  end
  else if (FIRST_SUM_STAGE == 1'b1) begin
    delay_pipeline[0] <= filter_in;
    delay_pipeline[1] <= delay_pipeline[0];
    delay_pipeline[2] <= delay_pipeline[1];
    delay_pipeline[3] <= delay_pipeline[2];
    delay_pipeline[4] <= delay_pipeline[3];
    delay_pipeline[5] <= delay_pipeline[4];
  end

wire[15:0] inputmux_1= (cur_count == 3'b000) ? delay_pipeline[0]:
                   (cur_count == 3'b001) ? delay_pipeline[1]:
                   (cur_count == 3'b010) ? delay_pipeline[2]:
                   (cur_count == 3'b011) ? delay_pipeline[3]:
                   (cur_count == 3'b100) ? delay_pipeline[4]:
                   delay_pipeline[5];
wire[15:0] product_1_mux= (cur_count == 3'b000) ? coeff1:
                   (cur_count == 3'b001) ? coeff2:
                   (cur_count == 3'b010) ? coeff3:
                   (cur_count == 3'b011) ? coeff4:
                   (cur_count == 3'b100) ? coeff5:
                   coeff6;
wire[31:0] mul_temp = inputmux_1 * product_1_mux;

wire signed [32:0] acc_sum_1; // sfix33_En31
wire signed [32:0] acc_in_1; // sfix33_En31
reg  signed [32:0] acc_out_1; // sfix33_En31

assign acc_sum_1 = {mul_temp[31],mul_temp} + acc_out_1;
assign acc_in_1 = (OUTPUT_STAGE == 1'b1)?{mul_temp[31],mul_temp}:acc_sum_1;
always @ ( posedge clk)
  if(syn_rst == 1'b1)
    acc_out_1 <= 0;   
  else if (clk_enable == 1'b1)
    acc_out_1 <= acc_in_1;  

reg  signed [32:0] acc_final; // sfix33_En31
always @ ( posedge clk)
  if (syn_rst == 1'b1)
    acc_final <= 0;
  else if (OUTPUT_STAGE == 1'b1)
    acc_final <= acc_out_1;

assign filter_out = (acc_final[31:0] + {acc_final[16], {15{~acc_final[16]}}})>>>16;

endmodule  // filter_serial
