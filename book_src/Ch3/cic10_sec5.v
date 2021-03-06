// -------------------------------------------------------------
// HDL Code Generation Options:
//
// ResetType: Synchronous
// OptimizeForHDL: on
// ResetInputPort: syn_rst
// TargetDirectory: E:\百度云同步盘\书籍\书稿\第三章
// Name: cic10_sec5
// TargetLanguage: Verilog
// TestBenchStimulus: step ramp chirp noise 

// -------------------------------------------------------------
// HDL Implementation    : Fully parallel
// -------------------------------------------------------------
// Filter Settings:
//
// Discrete-Time FIR Multirate Filter (real)
// -----------------------------------------
// Filter Structure        : Cascaded Integrator-Comb Decimator
// Decimation Factor       : 10
// Differential Delay      : 1
// Number of Sections      : 4
// Stable                  : Yes
// Linear Phase            : Yes (Type 1)
//
// Input                   : s16,15
// Output                  : s30,15
// Filter Internals        : Full Precision
//   Integrator Section 1  : s30,15
//   Integrator Section 2  : s30,15
//   Integrator Section 3  : s30,15
//   Integrator Section 4  : s30,15
//   Comb Section 1        : s30,15
//   Comb Section 2        : s30,15
//   Comb Section 3        : s30,15
//   Comb Section 4        : s30,15
// -------------------------------------------------------------
`timescale 1 ns / 1 ns

module cic10_sec5
               (
                clk,
                clk_enable,
                syn_rst,
                filter_in,
                filter_out,
                ce_out
                );

  input   clk; 
  input   clk_enable; 
  input   syn_rst; 
  input   signed [15:0] filter_in; //sfix16_En15
  output  signed [29:0] filter_out; //sfix30_En15
  output  ce_out; 

////////////////////////////////////////////////////////////////
//Module Architecture: cic10_sec5
////////////////////////////////////////////////////////////////
  // Local Functions
  // Type Definitions
  // Constants
  // Signals
  reg  [3:0] cur_count; // ufix4
  wire phase_1; // boolean
  reg  ce_out_reg; // boolean
  //   
  reg  signed [15:0] input_register; // sfix16_En15
  //   -- Section 1 Signals 
  wire signed [15:0] section_in1; // sfix16_En15
  wire signed [29:0] section_cast1; // sfix30_En15
  wire signed [29:0] sum1; // sfix30_En15
  reg  signed [29:0] section_out1; // sfix30_En15
  wire signed [29:0] add_cast; // sfix30_En15
  wire signed [29:0] add_cast_1; // sfix30_En15
  wire signed [30:0] add_temp; // sfix31_En15
  //   -- Section 2 Signals 
  wire signed [29:0] section_in2; // sfix30_En15
  wire signed [29:0] sum2; // sfix30_En15
  reg  signed [29:0] section_out2; // sfix30_En15
  wire signed [29:0] add_cast_2; // sfix30_En15
  wire signed [29:0] add_cast_3; // sfix30_En15
  wire signed [30:0] add_temp_1; // sfix31_En15
  //   -- Section 3 Signals 
  wire signed [29:0] section_in3; // sfix30_En15
  wire signed [29:0] sum3; // sfix30_En15
  reg  signed [29:0] section_out3; // sfix30_En15
  wire signed [29:0] add_cast_4; // sfix30_En15
  wire signed [29:0] add_cast_5; // sfix30_En15
  wire signed [30:0] add_temp_2; // sfix31_En15
  //   -- Section 4 Signals 
  wire signed [29:0] section_in4; // sfix30_En15
  wire signed [29:0] sum4; // sfix30_En15
  reg  signed [29:0] section_out4; // sfix30_En15
  wire signed [29:0] add_cast_6; // sfix30_En15
  wire signed [29:0] add_cast_7; // sfix30_En15
  wire signed [30:0] add_temp_3; // sfix31_En15
  //   -- Section 5 Signals 
  wire signed [29:0] section_in5; // sfix30_En15
  reg  signed [29:0] diff1; // sfix30_En15
  wire signed [29:0] section_out5; // sfix30_En15
  wire signed [29:0] sub_cast; // sfix30_En15
  wire signed [29:0] sub_cast_1; // sfix30_En15
  wire signed [30:0] sub_temp; // sfix31_En15
  //   -- Section 6 Signals 
  wire signed [29:0] section_in6; // sfix30_En15
  reg  signed [29:0] diff2; // sfix30_En15
  wire signed [29:0] section_out6; // sfix30_En15
  wire signed [29:0] sub_cast_2; // sfix30_En15
  wire signed [29:0] sub_cast_3; // sfix30_En15
  wire signed [30:0] sub_temp_1; // sfix31_En15
  //   -- Section 7 Signals 
  wire signed [29:0] section_in7; // sfix30_En15
  reg  signed [29:0] diff3; // sfix30_En15
  wire signed [29:0] section_out7; // sfix30_En15
  wire signed [29:0] sub_cast_4; // sfix30_En15
  wire signed [29:0] sub_cast_5; // sfix30_En15
  wire signed [30:0] sub_temp_2; // sfix31_En15
  //   -- Section 8 Signals 
  wire signed [29:0] section_in8; // sfix30_En15
  reg  signed [29:0] diff4; // sfix30_En15
  wire signed [29:0] section_out8; // sfix30_En15
  wire signed [29:0] sub_cast_6; // sfix30_En15
  wire signed [29:0] sub_cast_7; // sfix30_En15
  wire signed [30:0] sub_temp_3; // sfix31_En15
  //   
  reg  signed [29:0] output_register; // sfix30_En15

  // Block Statements
  //   ------------------ CE Output Generation ------------------

  always @ ( posedge clk)
    begin: ce_output
      if (syn_rst == 1'b1) begin
        cur_count <= 4'b0000;
      end
      else begin
        if (clk_enable == 1'b1) begin
          if (cur_count == 4'b1001) begin
            cur_count <= 4'b0000;
          end
          else begin
            cur_count <= cur_count + 1;
          end
        end
      end
    end // ce_output

  assign  phase_1 = (cur_count == 4'b0001 && clk_enable == 1'b1)? 1 : 0;

  //   ------------------ CE Output Register ------------------

  always @ ( posedge clk)
    begin: ce_output_register
      if (syn_rst == 1'b1) begin
        ce_out_reg <= 1'b0;
      end
      else begin
          ce_out_reg <= phase_1;
      end
    end // ce_output_register

  //   ------------------ Input Register ------------------

  always @ ( posedge clk)
    begin: input_reg_process
      if (syn_rst == 1'b1) begin
        input_register <= 0;
      end
      else begin
        if (clk_enable == 1'b1) begin
          input_register <= filter_in;
        end
      end
    end // input_reg_process

  //   ------------------ Section # 1 : Integrator ------------------

  assign section_in1 = input_register;

  assign section_cast1 = $signed({{14{section_in1[15]}}, section_in1});

  assign add_cast = section_cast1;
  assign add_cast_1 = section_out1;
  assign add_temp = add_cast + add_cast_1;
  assign sum1 = add_temp[29:0];

  always @ ( posedge clk)
    begin: integrator_delay_section1
      if (syn_rst == 1'b1) begin
        section_out1 <= 0;
      end
      else begin
        if (clk_enable == 1'b1) begin
          section_out1 <= sum1;
        end
      end
    end // integrator_delay_section1

  //   ------------------ Section # 2 : Integrator ------------------

  assign section_in2 = section_out1;

  assign add_cast_2 = section_in2;
  assign add_cast_3 = section_out2;
  assign add_temp_1 = add_cast_2 + add_cast_3;
  assign sum2 = add_temp_1[29:0];

  always @ ( posedge clk)
    begin: integrator_delay_section2
      if (syn_rst == 1'b1) begin
        section_out2 <= 0;
      end
      else begin
        if (clk_enable == 1'b1) begin
          section_out2 <= sum2;
        end
      end
    end // integrator_delay_section2

  //   ------------------ Section # 3 : Integrator ------------------

  assign section_in3 = section_out2;

  assign add_cast_4 = section_in3;
  assign add_cast_5 = section_out3;
  assign add_temp_2 = add_cast_4 + add_cast_5;
  assign sum3 = add_temp_2[29:0];

  always @ ( posedge clk)
    begin: integrator_delay_section3
      if (syn_rst == 1'b1) begin
        section_out3 <= 0;
      end
      else begin
        if (clk_enable == 1'b1) begin
          section_out3 <= sum3;
        end
      end
    end // integrator_delay_section3

  //   ------------------ Section # 4 : Integrator ------------------

  assign section_in4 = section_out3;

  assign add_cast_6 = section_in4;
  assign add_cast_7 = section_out4;
  assign add_temp_3 = add_cast_6 + add_cast_7;
  assign sum4 = add_temp_3[29:0];

  always @ ( posedge clk)
    begin: integrator_delay_section4
      if (syn_rst == 1'b1) begin
        section_out4 <= 0;
      end
      else begin
        if (clk_enable == 1'b1) begin
          section_out4 <= sum4;
        end
      end
    end // integrator_delay_section4

  //   ------------------ Section # 5 : Comb ------------------

  assign section_in5 = section_out4;

  assign sub_cast = section_in5;
  assign sub_cast_1 = diff1;
  assign sub_temp = sub_cast - sub_cast_1;
  assign section_out5 = sub_temp[29:0];

  always @ ( posedge clk)
    begin: comb_delay_section5
      if (syn_rst == 1'b1) begin
        diff1 <= 0;
      end
      else begin
        if (phase_1 == 1'b1) begin
          diff1 <= section_in5;
        end
      end
    end // comb_delay_section5

  //   ------------------ Section # 6 : Comb ------------------

  assign section_in6 = section_out5;

  assign sub_cast_2 = section_in6;
  assign sub_cast_3 = diff2;
  assign sub_temp_1 = sub_cast_2 - sub_cast_3;
  assign section_out6 = sub_temp_1[29:0];

  always @ ( posedge clk)
    begin: comb_delay_section6
      if (syn_rst == 1'b1) begin
        diff2 <= 0;
      end
      else begin
        if (phase_1 == 1'b1) begin
          diff2 <= section_in6;
        end
      end
    end // comb_delay_section6

  //   ------------------ Section # 7 : Comb ------------------

  assign section_in7 = section_out6;

  assign sub_cast_4 = section_in7;
  assign sub_cast_5 = diff3;
  assign sub_temp_2 = sub_cast_4 - sub_cast_5;
  assign section_out7 = sub_temp_2[29:0];

  always @ ( posedge clk)
    begin: comb_delay_section7
      if (syn_rst == 1'b1) begin
        diff3 <= 0;
      end
      else begin
        if (phase_1 == 1'b1) begin
          diff3 <= section_in7;
        end
      end
    end // comb_delay_section7

  //   ------------------ Section # 8 : Comb ------------------

  assign section_in8 = section_out7;

  assign sub_cast_6 = section_in8;
  assign sub_cast_7 = diff4;
  assign sub_temp_3 = sub_cast_6 - sub_cast_7;
  assign section_out8 = sub_temp_3[29:0];

  always @ ( posedge clk)
    begin: comb_delay_section8
      if (syn_rst == 1'b1) begin
        diff4 <= 0;
      end
      else begin
        if (phase_1 == 1'b1) begin
          diff4 <= section_in8;
        end
      end
    end // comb_delay_section8

  //   ------------------ Output Register ------------------

  always @ ( posedge clk)
    begin: output_reg_process
      if (syn_rst == 1'b1) begin
        output_register <= 0;
      end
      else begin
        if (phase_1 == 1'b1) begin
          output_register <= section_out8;
        end
      end
    end // output_reg_process

  // Assignment Statements
  assign ce_out = ce_out_reg;
  assign filter_out = output_register;
endmodule  // cic10_sec5
