// -------------------------------------------------------------
// HDL Code Generation Options:
//
// ResetType: Synchronous
// OptimizeForHDL: on
// ResetInputPort: syn_rst
// TargetDirectory: E:\百度云同步盘\书籍\书稿\第三章
// AddInputRegister: off
// InputPort: cic_in
// OutputPort: cic_out
// Name: my_cic
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
// Decimation Factor       : 5
// Differential Delay      : 1
// Number of Sections      : 1
// Stable                  : Yes
// Linear Phase            : Yes (Type 1)
//
// Input                   : s16,15
// Output                  : s19,15
// Filter Internals        : Full Precision
//   Integrator Section 1  : s19,15
//   Comb Section 1        : s19,15
// -------------------------------------------------------------

`timescale 1 ns / 1 ns

module my_cic
               (
                clk,
                clk_enable,
                syn_rst,
                cic_in,
                cic_out,
                ce_out
                );

  input   clk; 
  input   clk_enable; 
  input   syn_rst; 
  input   signed [15:0] cic_in; //sfix16_En15
  output  signed [18:0] cic_out; //sfix19_En15
  output  ce_out; 

////////////////////////////////////////////////////////////////
//Module Architecture: my_cic
////////////////////////////////////////////////////////////////
  // Local Functions
  // Type Definitions
  // Constants
  // Signals
  wire signed [15:0] input_typeconvert; // sfix16_En15
  reg  [2:0] cur_count; // ufix3
  wire phase_0; // boolean
  reg  ce_out_reg; // boolean
  //   -- Section 1 Signals 
  wire signed [15:0] section_in1; // sfix16_En15
  wire signed [18:0] section_cast1; // sfix19_En15
  wire signed [18:0] sum1; // sfix19_En15
  reg  signed [18:0] section_out1; // sfix19_En15
  wire signed [18:0] add_cast; // sfix19_En15
  wire signed [18:0] add_cast_1; // sfix19_En15
  wire signed [19:0] add_temp; // sfix20_En15
  //   -- Section 2 Signals 
  wire signed [18:0] section_in2; // sfix19_En15
  reg  signed [18:0] diff1; // sfix19_En15
  wire signed [18:0] section_out2; // sfix19_En15
  wire signed [18:0] sub_cast; // sfix19_En15
  wire signed [18:0] sub_cast_1; // sfix19_En15
  wire signed [19:0] sub_temp; // sfix20_En15
  //   
  reg  signed [18:0] output_register; // sfix19_En15

  // Block Statements
  //   ------------------ CE Output Generation ------------------

  always @ ( posedge clk)
    begin: ce_output
      if (syn_rst == 1'b1) begin
        cur_count <= 3'b000;
      end
      else begin
        if (clk_enable == 1'b1) begin
          if (cur_count == 3'b100) begin
            cur_count <= 3'b000;
          end
          else begin
            cur_count <= cur_count + 1;
          end
        end
      end
    end // ce_output

  assign  phase_0 = (cur_count == 3'b000 && clk_enable == 1'b1)? 1 : 0;

  //   ------------------ CE Output Register ------------------

  always @ ( posedge clk)
    begin: ce_output_register
      if (syn_rst == 1'b1) begin
        ce_out_reg <= 1'b0;
      end
      else begin
          ce_out_reg <= phase_0;
      end
    end // ce_output_register

  assign input_typeconvert = cic_in;

  //   ------------------ Section # 1 : Integrator ------------------

  assign section_in1 = input_typeconvert;

  assign section_cast1 = $signed({{3{section_in1[15]}}, section_in1});

  assign add_cast = section_cast1;
  assign add_cast_1 = section_out1;
  assign add_temp = add_cast + add_cast_1;
  assign sum1 = add_temp[18:0];

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

  //   ------------------ Section # 2 : Comb ------------------

  assign section_in2 = section_out1;

  assign sub_cast = section_in2;
  assign sub_cast_1 = diff1;
  assign sub_temp = sub_cast - sub_cast_1;
  assign section_out2 = sub_temp[18:0];

  always @ ( posedge clk)
    begin: comb_delay_section2
      if (syn_rst == 1'b1) begin
        diff1 <= 0;
      end
      else begin
        if (phase_0 == 1'b1) begin
          diff1 <= section_in2;
        end
      end
    end // comb_delay_section2

  //   ------------------ Output Register ------------------

  always @ ( posedge clk)
    begin: output_reg_process
      if (syn_rst == 1'b1) begin
        output_register <= 0;
      end
      else begin
        if (phase_0 == 1'b1) begin
          output_register <= section_out2;
        end
      end
    end // output_reg_process

  // Assignment Statements
  assign ce_out = ce_out_reg;
  assign cic_out = output_register;
endmodule  // my_cic
