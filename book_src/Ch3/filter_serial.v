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

module filter_serial
               (
                clk,
                clk_enable,
                syn_rst,
                filter_in,
                filter_out
                );

  input   clk; 
  input   clk_enable; 
  input   syn_rst; 
  input   signed [15:0] filter_in; //sfix16_En15
  output  signed [15:0] filter_out; //sfix16_En15

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
  reg  [2:0] cur_count; // ufix3
  wire phase_5; // boolean
  wire phase_0; // boolean
  reg  signed [15:0] delay_pipeline [0:5] ; // sfix16_En15
  wire signed [15:0] inputmux_1; // sfix16_En15
  reg  signed [32:0] acc_final; // sfix33_En31
  reg  signed [32:0] acc_out_1; // sfix33_En31
  wire signed [30:0] product_1; // sfix31_En31
  wire signed [15:0] product_1_mux; // sfix16_En16
  wire signed [31:0] mul_temp; // sfix32_En31
  wire signed [32:0] prod_typeconvert_1; // sfix33_En31
  wire signed [32:0] acc_sum_1; // sfix33_En31
  wire signed [32:0] acc_in_1; // sfix33_En31
  wire signed [32:0] add_signext; // sfix33_En31
  wire signed [32:0] add_signext_1; // sfix33_En31
  wire signed [33:0] add_temp; // sfix34_En31
  wire signed [15:0] output_typeconvert; // sfix16_En15

  // Block Statements
  always @ ( posedge clk)
    begin: Counter_process
      if (syn_rst == 1'b1) begin
        cur_count <= 3'b101;
      end
      else begin
        if (clk_enable == 1'b1) begin
          if (cur_count == 3'b101) begin
            cur_count <= 3'b000;
          end
          else begin
            cur_count <= cur_count + 1;
          end
        end
      end
    end // Counter_process

  assign  phase_5 = (cur_count == 3'b101 && clk_enable == 1'b1)? 1 : 0;

  assign  phase_0 = (cur_count == 3'b000 && clk_enable == 1'b1)? 1 : 0;

  always @( posedge clk)
    begin: Delay_Pipeline_process
      if (syn_rst == 1'b1) begin
        delay_pipeline[0] <= 0;
        delay_pipeline[1] <= 0;
        delay_pipeline[2] <= 0;
        delay_pipeline[3] <= 0;
        delay_pipeline[4] <= 0;
        delay_pipeline[5] <= 0;
      end
      else begin
        if (phase_5 == 1'b1) begin
          delay_pipeline[0] <= filter_in;
          delay_pipeline[1] <= delay_pipeline[0];
          delay_pipeline[2] <= delay_pipeline[1];
          delay_pipeline[3] <= delay_pipeline[2];
          delay_pipeline[4] <= delay_pipeline[3];
          delay_pipeline[5] <= delay_pipeline[4];
        end
      end
    end // Delay_Pipeline_process


  assign inputmux_1 = (cur_count == 3'b000) ? delay_pipeline[0] :
                     (cur_count == 3'b001) ? delay_pipeline[1] :
                     (cur_count == 3'b010) ? delay_pipeline[2] :
                     (cur_count == 3'b011) ? delay_pipeline[3] :
                     (cur_count == 3'b100) ? delay_pipeline[4] :
                     delay_pipeline[5];

  //   ------------------ Serial partition # 1 ------------------

  assign product_1_mux = (cur_count == 3'b000) ? coeff1 :
                        (cur_count == 3'b001) ? coeff2 :
                        (cur_count == 3'b010) ? coeff3 :
                        (cur_count == 3'b011) ? coeff4 :
                        (cur_count == 3'b100) ? coeff5 :
                        coeff6;
  assign mul_temp = inputmux_1 * product_1_mux;
  assign product_1 = mul_temp[30:0];

  assign prod_typeconvert_1 = $signed({{2{product_1[30]}}, product_1});

  assign add_signext = prod_typeconvert_1;
  assign add_signext_1 = acc_out_1;
  assign add_temp = add_signext + add_signext_1;
  assign acc_sum_1 = add_temp[32:0];

  assign acc_in_1 = (phase_0 == 1'b1) ? prod_typeconvert_1 :
                   acc_sum_1;

  always @ ( posedge clk)
    begin: Acc_reg_1_process
      if (syn_rst == 1'b1) begin
        acc_out_1 <= 0;
      end
      else begin
        if (clk_enable == 1'b1) begin
          acc_out_1 <= acc_in_1;
        end
      end
    end // Acc_reg_1_process

  always @ ( posedge clk)
    begin: Finalsum_reg_process
      if (syn_rst == 1'b1) begin
        acc_final <= 0;
      end
      else begin
        if (phase_0 == 1'b1) begin
          acc_final <= acc_out_1;
        end
      end
    end // Finalsum_reg_process

  assign output_typeconvert = (acc_final[31:0] + {acc_final[16], {15{~acc_final[16]}}})>>>16;

  // Assignment Statements
  assign filter_out = output_typeconvert;
endmodule  // filter_serial
