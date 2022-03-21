// -------------------------------------------------------------
// HDL Code Generation Options:
//
// ResetType: Synchronous
// FIRAdderStyle: tree
// ResetInputPort: syn_rst
// TargetDirectory: E:\百度云同步盘\书籍\书稿\第三章
// Name: fir_da
// RemoveResetFrom: ShiftRegister
// DALUTPartition: 5
// DARadix: 256
// TargetLanguage: Verilog
// TestBenchStimulus: impulse step ramp chirp noise 

// -------------------------------------------------------------
// HDL Implementation    : Distributed arithmetic (DA)
// Folding Factor        : 1
// LUT Address Width     : 5
// Total LUT Size (bits) : 4608
// -------------------------------------------------------------
// Filter Settings:
//
// Discrete-Time FIR Filter (real)
// -------------------------------
// Filter Structure  : Direct-Form FIR
// Filter Length     : 5
// Stable            : Yes
// Linear Phase      : Yes (Type 1)
// Arithmetic        : fixed
// Numerator         : s16,19 -> [-6.250000e-02 6.250000e-02)
// Input             : s8,7 -> [-1 1)
// Filter Internals  : Specify Precision
//   Output          : s8,7 -> [-1 1)
//   Product         : s31,31 -> [-5.000000e-01 5.000000e-01)
//   Accumulator     : s33,31 -> [-2 2)
//   Round Mode      : convergent
//   Overflow Mode   : wrap
// -------------------------------------------------------------

`timescale 1 ns / 1 ns

module fir_da
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
  input   signed [7:0] filter_in; //sfix8_En7
  output  signed [7:0] filter_out; //sfix8_En7

////////////////////////////////////////////////////////////////
//Module Architecture: fir_da
////////////////////////////////////////////////////////////////
  // Local Functions
  // Type Definitions
  // Constants
  parameter signed [15:0] coeff1 = 16'b0011000010100000; //sfix16_En19
  parameter signed [15:0] coeff2 = 16'b0110000101000000; //sfix16_En19
  parameter signed [15:0] coeff3 = 16'b0111100110010000; //sfix16_En19
  parameter signed [15:0] coeff4 = 16'b0110000101000000; //sfix16_En19
  parameter signed [15:0] coeff5 = 16'b0011000010100000; //sfix16_En19

  // Signals
  reg  signed [7:0] input_register; // sfix8_En7
  wire filter_in_1; // boolean
  wire filter_in_2; // boolean
  wire filter_in_3; // boolean
  wire filter_in_4; // boolean
  wire filter_in_5; // boolean
  wire filter_in_6; // boolean
  wire filter_in_7; // boolean
  wire filter_in_8; // boolean
  reg  delay_pipeline_1 [0:3] ; // boolean
  reg  delay_pipeline_2 [0:3] ; // boolean
  reg  delay_pipeline_3 [0:3] ; // boolean
  reg  delay_pipeline_4 [0:3] ; // boolean
  reg  delay_pipeline_5 [0:3] ; // boolean
  reg  delay_pipeline_6 [0:3] ; // boolean
  reg  delay_pipeline_7 [0:3] ; // boolean
  reg  delay_pipeline_8 [0:3] ; // boolean
  wire [4:0] mem_addrb1; // ufix5
  reg  signed [17:0] memoutb1; // sfix18_En19
  wire [4:0] mem_addrb2; // ufix5
  reg  signed [17:0] memoutb2; // sfix18_En18
  wire [4:0] mem_addrb3; // ufix5
  reg  signed [17:0] memoutb3; // sfix18_En19
  wire [4:0] mem_addrb4; // ufix5
  reg  signed [17:0] memoutb4; // sfix18_En18
  wire [4:0] mem_addrb5; // ufix5
  reg  signed [17:0] memoutb5; // sfix18_En19
  wire [4:0] mem_addrb6; // ufix5
  reg  signed [17:0] memoutb6; // sfix18_En18
  wire [4:0] mem_addrb7; // ufix5
  reg  signed [17:0] memoutb7; // sfix18_En19
  wire [4:0] mem_addrb8; // ufix5
  reg  signed [17:0] memoutb8; // sfix18_En18
  wire signed [17:0] lut_msb; // sfix18_En18
  wire signed [18:0] unaryminus_temp; // sfix19_En18
  wire signed [19:0] memsum1_1; // sfix20_En19
  wire signed [18:0] add_signext; // sfix19_En19
  wire signed [18:0] add_signext_1; // sfix19_En19
  wire signed [19:0] memsum1_2; // sfix20_En19
  wire signed [18:0] add_signext_2; // sfix19_En19
  wire signed [18:0] add_signext_3; // sfix19_En19
  wire signed [19:0] memsum1_3; // sfix20_En19
  wire signed [18:0] add_signext_4; // sfix19_En19
  wire signed [18:0] add_signext_5; // sfix19_En19
  wire signed [19:0] memsum1_4; // sfix20_En19
  wire signed [18:0] add_signext_6; // sfix19_En19
  wire signed [18:0] add_signext_7; // sfix19_En19
  wire signed [19:0] memsumshft2_1; // sfix20_En17
  wire signed [22:0] memsum2_1; // sfix23_En19
  wire signed [21:0] add_signext_8; // sfix22_En19
  wire signed [21:0] add_signext_9; // sfix22_En19
  wire signed [19:0] memsumshft2_2; // sfix20_En17
  wire signed [22:0] memsum2_2; // sfix23_En19
  wire signed [21:0] add_signext_10; // sfix22_En19
  wire signed [21:0] add_signext_11; // sfix22_En19
  wire signed [22:0] memsumshft3_1; // sfix23_En15
  wire signed [27:0] memsum3_1; // sfix28_En19
  wire signed [26:0] add_signext_12; // sfix27_En19
  wire signed [26:0] add_signext_13; // sfix27_En19
  wire signed [27:0] output_da; // sfix28_En26
  wire signed [7:0] output_typeconvert; // sfix8_En7
  reg  signed [7:0] output_register; // sfix8_En7

  // Block Statements
  always @ ( posedge clk)
    begin: Input_Register_process
      if (syn_rst == 1'b1) begin
        input_register <= 0;
      end
      else begin
        if (clk_enable == 1'b1) begin
          input_register <= filter_in;
        end
      end
    end // Input_Register_process

  assign filter_in_1 = {input_register[0]};

  assign filter_in_2 = {input_register[1]};

  assign filter_in_3 = {input_register[2]};

  assign filter_in_4 = {input_register[3]};

  assign filter_in_5 = {input_register[4]};

  assign filter_in_6 = {input_register[5]};

  assign filter_in_7 = {input_register[6]};

  assign filter_in_8 = {input_register[7]};

  always @( posedge clk)
    begin: Delay_Pipeline_1_process
      if (syn_rst == 1'b1) begin
        delay_pipeline_1[0] <= 1'b0;
        delay_pipeline_1[1] <= 1'b0;
        delay_pipeline_1[2] <= 1'b0;
        delay_pipeline_1[3] <= 1'b0;
      end
      else begin
        if (clk_enable == 1'b1) begin
          delay_pipeline_1[0] <= filter_in_1;
          delay_pipeline_1[1] <= delay_pipeline_1[0];
          delay_pipeline_1[2] <= delay_pipeline_1[1];
          delay_pipeline_1[3] <= delay_pipeline_1[2];
        end
      end
    end // Delay_Pipeline_1_process


  always @( posedge clk)
    begin: Delay_Pipeline_2_process
      if (syn_rst == 1'b1) begin
        delay_pipeline_2[0] <= 1'b0;
        delay_pipeline_2[1] <= 1'b0;
        delay_pipeline_2[2] <= 1'b0;
        delay_pipeline_2[3] <= 1'b0;
      end
      else begin
        if (clk_enable == 1'b1) begin
          delay_pipeline_2[0] <= filter_in_2;
          delay_pipeline_2[1] <= delay_pipeline_2[0];
          delay_pipeline_2[2] <= delay_pipeline_2[1];
          delay_pipeline_2[3] <= delay_pipeline_2[2];
        end
      end
    end // Delay_Pipeline_2_process


  always @( posedge clk)
    begin: Delay_Pipeline_3_process
      if (syn_rst == 1'b1) begin
        delay_pipeline_3[0] <= 1'b0;
        delay_pipeline_3[1] <= 1'b0;
        delay_pipeline_3[2] <= 1'b0;
        delay_pipeline_3[3] <= 1'b0;
      end
      else begin
        if (clk_enable == 1'b1) begin
          delay_pipeline_3[0] <= filter_in_3;
          delay_pipeline_3[1] <= delay_pipeline_3[0];
          delay_pipeline_3[2] <= delay_pipeline_3[1];
          delay_pipeline_3[3] <= delay_pipeline_3[2];
        end
      end
    end // Delay_Pipeline_3_process


  always @( posedge clk)
    begin: Delay_Pipeline_4_process
      if (syn_rst == 1'b1) begin
        delay_pipeline_4[0] <= 1'b0;
        delay_pipeline_4[1] <= 1'b0;
        delay_pipeline_4[2] <= 1'b0;
        delay_pipeline_4[3] <= 1'b0;
      end
      else begin
        if (clk_enable == 1'b1) begin
          delay_pipeline_4[0] <= filter_in_4;
          delay_pipeline_4[1] <= delay_pipeline_4[0];
          delay_pipeline_4[2] <= delay_pipeline_4[1];
          delay_pipeline_4[3] <= delay_pipeline_4[2];
        end
      end
    end // Delay_Pipeline_4_process


  always @( posedge clk)
    begin: Delay_Pipeline_5_process
      if (syn_rst == 1'b1) begin
        delay_pipeline_5[0] <= 1'b0;
        delay_pipeline_5[1] <= 1'b0;
        delay_pipeline_5[2] <= 1'b0;
        delay_pipeline_5[3] <= 1'b0;
      end
      else begin
        if (clk_enable == 1'b1) begin
          delay_pipeline_5[0] <= filter_in_5;
          delay_pipeline_5[1] <= delay_pipeline_5[0];
          delay_pipeline_5[2] <= delay_pipeline_5[1];
          delay_pipeline_5[3] <= delay_pipeline_5[2];
        end
      end
    end // Delay_Pipeline_5_process


  always @( posedge clk)
    begin: Delay_Pipeline_6_process
      if (syn_rst == 1'b1) begin
        delay_pipeline_6[0] <= 1'b0;
        delay_pipeline_6[1] <= 1'b0;
        delay_pipeline_6[2] <= 1'b0;
        delay_pipeline_6[3] <= 1'b0;
      end
      else begin
        if (clk_enable == 1'b1) begin
          delay_pipeline_6[0] <= filter_in_6;
          delay_pipeline_6[1] <= delay_pipeline_6[0];
          delay_pipeline_6[2] <= delay_pipeline_6[1];
          delay_pipeline_6[3] <= delay_pipeline_6[2];
        end
      end
    end // Delay_Pipeline_6_process


  always @( posedge clk)
    begin: Delay_Pipeline_7_process
      if (syn_rst == 1'b1) begin
        delay_pipeline_7[0] <= 1'b0;
        delay_pipeline_7[1] <= 1'b0;
        delay_pipeline_7[2] <= 1'b0;
        delay_pipeline_7[3] <= 1'b0;
      end
      else begin
        if (clk_enable == 1'b1) begin
          delay_pipeline_7[0] <= filter_in_7;
          delay_pipeline_7[1] <= delay_pipeline_7[0];
          delay_pipeline_7[2] <= delay_pipeline_7[1];
          delay_pipeline_7[3] <= delay_pipeline_7[2];
        end
      end
    end // Delay_Pipeline_7_process


  always @( posedge clk)
    begin: Delay_Pipeline_8_process
      if (syn_rst == 1'b1) begin
        delay_pipeline_8[0] <= 1'b0;
        delay_pipeline_8[1] <= 1'b0;
        delay_pipeline_8[2] <= 1'b0;
        delay_pipeline_8[3] <= 1'b0;
      end
      else begin
        if (clk_enable == 1'b1) begin
          delay_pipeline_8[0] <= filter_in_8;
          delay_pipeline_8[1] <= delay_pipeline_8[0];
          delay_pipeline_8[2] <= delay_pipeline_8[1];
          delay_pipeline_8[3] <= delay_pipeline_8[2];
        end
      end
    end // Delay_Pipeline_8_process


  assign mem_addrb1 = {delay_pipeline_1[3], delay_pipeline_1[2], delay_pipeline_1[1], delay_pipeline_1[0], filter_in_1};

  always @(mem_addrb1)
  begin
    case(mem_addrb1)
      5'b00000 : memoutb1 = 18'b000000000000000000;
      5'b00001 : memoutb1 = 18'b000011000010100000;
      5'b00010 : memoutb1 = 18'b000110000101000000;
      5'b00011 : memoutb1 = 18'b001001000111100000;
      5'b00100 : memoutb1 = 18'b000111100110010000;
      5'b00101 : memoutb1 = 18'b001010101000110000;
      5'b00110 : memoutb1 = 18'b001101101011010000;
      5'b00111 : memoutb1 = 18'b010000101101110000;
      5'b01000 : memoutb1 = 18'b000110000101000000;
      5'b01001 : memoutb1 = 18'b001001000111100000;
      5'b01010 : memoutb1 = 18'b001100001010000000;
      5'b01011 : memoutb1 = 18'b001111001100100000;
      5'b01100 : memoutb1 = 18'b001101101011010000;
      5'b01101 : memoutb1 = 18'b010000101101110000;
      5'b01110 : memoutb1 = 18'b010011110000010000;
      5'b01111 : memoutb1 = 18'b010110110010110000;
      5'b10000 : memoutb1 = 18'b000011000010100000;
      5'b10001 : memoutb1 = 18'b000110000101000000;
      5'b10010 : memoutb1 = 18'b001001000111100000;
      5'b10011 : memoutb1 = 18'b001100001010000000;
      5'b10100 : memoutb1 = 18'b001010101000110000;
      5'b10101 : memoutb1 = 18'b001101101011010000;
      5'b10110 : memoutb1 = 18'b010000101101110000;
      5'b10111 : memoutb1 = 18'b010011110000010000;
      5'b11000 : memoutb1 = 18'b001001000111100000;
      5'b11001 : memoutb1 = 18'b001100001010000000;
      5'b11010 : memoutb1 = 18'b001111001100100000;
      5'b11011 : memoutb1 = 18'b010010001111000000;
      5'b11100 : memoutb1 = 18'b010000101101110000;
      5'b11101 : memoutb1 = 18'b010011110000010000;
      5'b11110 : memoutb1 = 18'b010110110010110000;
      5'b11111 : memoutb1 = 18'b011001110101010000;
      default : memoutb1 = 18'b011001110101010000;
    endcase
  end

  assign mem_addrb2 = {delay_pipeline_2[3], delay_pipeline_2[2], delay_pipeline_2[1], delay_pipeline_2[0], filter_in_2};

  always @(mem_addrb2)
  begin
    case(mem_addrb2)
      5'b00000 : memoutb2 = 18'b000000000000000000;
      5'b00001 : memoutb2 = 18'b000011000010100000;
      5'b00010 : memoutb2 = 18'b000110000101000000;
      5'b00011 : memoutb2 = 18'b001001000111100000;
      5'b00100 : memoutb2 = 18'b000111100110010000;
      5'b00101 : memoutb2 = 18'b001010101000110000;
      5'b00110 : memoutb2 = 18'b001101101011010000;
      5'b00111 : memoutb2 = 18'b010000101101110000;
      5'b01000 : memoutb2 = 18'b000110000101000000;
      5'b01001 : memoutb2 = 18'b001001000111100000;
      5'b01010 : memoutb2 = 18'b001100001010000000;
      5'b01011 : memoutb2 = 18'b001111001100100000;
      5'b01100 : memoutb2 = 18'b001101101011010000;
      5'b01101 : memoutb2 = 18'b010000101101110000;
      5'b01110 : memoutb2 = 18'b010011110000010000;
      5'b01111 : memoutb2 = 18'b010110110010110000;
      5'b10000 : memoutb2 = 18'b000011000010100000;
      5'b10001 : memoutb2 = 18'b000110000101000000;
      5'b10010 : memoutb2 = 18'b001001000111100000;
      5'b10011 : memoutb2 = 18'b001100001010000000;
      5'b10100 : memoutb2 = 18'b001010101000110000;
      5'b10101 : memoutb2 = 18'b001101101011010000;
      5'b10110 : memoutb2 = 18'b010000101101110000;
      5'b10111 : memoutb2 = 18'b010011110000010000;
      5'b11000 : memoutb2 = 18'b001001000111100000;
      5'b11001 : memoutb2 = 18'b001100001010000000;
      5'b11010 : memoutb2 = 18'b001111001100100000;
      5'b11011 : memoutb2 = 18'b010010001111000000;
      5'b11100 : memoutb2 = 18'b010000101101110000;
      5'b11101 : memoutb2 = 18'b010011110000010000;
      5'b11110 : memoutb2 = 18'b010110110010110000;
      5'b11111 : memoutb2 = 18'b011001110101010000;
      default : memoutb2 = 18'b011001110101010000;
    endcase
  end

  assign mem_addrb3 = {delay_pipeline_3[3], delay_pipeline_3[2], delay_pipeline_3[1], delay_pipeline_3[0], filter_in_3};

  always @(mem_addrb3)
  begin
    case(mem_addrb3)
      5'b00000 : memoutb3 = 18'b000000000000000000;
      5'b00001 : memoutb3 = 18'b000011000010100000;
      5'b00010 : memoutb3 = 18'b000110000101000000;
      5'b00011 : memoutb3 = 18'b001001000111100000;
      5'b00100 : memoutb3 = 18'b000111100110010000;
      5'b00101 : memoutb3 = 18'b001010101000110000;
      5'b00110 : memoutb3 = 18'b001101101011010000;
      5'b00111 : memoutb3 = 18'b010000101101110000;
      5'b01000 : memoutb3 = 18'b000110000101000000;
      5'b01001 : memoutb3 = 18'b001001000111100000;
      5'b01010 : memoutb3 = 18'b001100001010000000;
      5'b01011 : memoutb3 = 18'b001111001100100000;
      5'b01100 : memoutb3 = 18'b001101101011010000;
      5'b01101 : memoutb3 = 18'b010000101101110000;
      5'b01110 : memoutb3 = 18'b010011110000010000;
      5'b01111 : memoutb3 = 18'b010110110010110000;
      5'b10000 : memoutb3 = 18'b000011000010100000;
      5'b10001 : memoutb3 = 18'b000110000101000000;
      5'b10010 : memoutb3 = 18'b001001000111100000;
      5'b10011 : memoutb3 = 18'b001100001010000000;
      5'b10100 : memoutb3 = 18'b001010101000110000;
      5'b10101 : memoutb3 = 18'b001101101011010000;
      5'b10110 : memoutb3 = 18'b010000101101110000;
      5'b10111 : memoutb3 = 18'b010011110000010000;
      5'b11000 : memoutb3 = 18'b001001000111100000;
      5'b11001 : memoutb3 = 18'b001100001010000000;
      5'b11010 : memoutb3 = 18'b001111001100100000;
      5'b11011 : memoutb3 = 18'b010010001111000000;
      5'b11100 : memoutb3 = 18'b010000101101110000;
      5'b11101 : memoutb3 = 18'b010011110000010000;
      5'b11110 : memoutb3 = 18'b010110110010110000;
      5'b11111 : memoutb3 = 18'b011001110101010000;
      default : memoutb3 = 18'b011001110101010000;
    endcase
  end

  assign mem_addrb4 = {delay_pipeline_4[3], delay_pipeline_4[2], delay_pipeline_4[1], delay_pipeline_4[0], filter_in_4};

  always @(mem_addrb4)
  begin
    case(mem_addrb4)
      5'b00000 : memoutb4 = 18'b000000000000000000;
      5'b00001 : memoutb4 = 18'b000011000010100000;
      5'b00010 : memoutb4 = 18'b000110000101000000;
      5'b00011 : memoutb4 = 18'b001001000111100000;
      5'b00100 : memoutb4 = 18'b000111100110010000;
      5'b00101 : memoutb4 = 18'b001010101000110000;
      5'b00110 : memoutb4 = 18'b001101101011010000;
      5'b00111 : memoutb4 = 18'b010000101101110000;
      5'b01000 : memoutb4 = 18'b000110000101000000;
      5'b01001 : memoutb4 = 18'b001001000111100000;
      5'b01010 : memoutb4 = 18'b001100001010000000;
      5'b01011 : memoutb4 = 18'b001111001100100000;
      5'b01100 : memoutb4 = 18'b001101101011010000;
      5'b01101 : memoutb4 = 18'b010000101101110000;
      5'b01110 : memoutb4 = 18'b010011110000010000;
      5'b01111 : memoutb4 = 18'b010110110010110000;
      5'b10000 : memoutb4 = 18'b000011000010100000;
      5'b10001 : memoutb4 = 18'b000110000101000000;
      5'b10010 : memoutb4 = 18'b001001000111100000;
      5'b10011 : memoutb4 = 18'b001100001010000000;
      5'b10100 : memoutb4 = 18'b001010101000110000;
      5'b10101 : memoutb4 = 18'b001101101011010000;
      5'b10110 : memoutb4 = 18'b010000101101110000;
      5'b10111 : memoutb4 = 18'b010011110000010000;
      5'b11000 : memoutb4 = 18'b001001000111100000;
      5'b11001 : memoutb4 = 18'b001100001010000000;
      5'b11010 : memoutb4 = 18'b001111001100100000;
      5'b11011 : memoutb4 = 18'b010010001111000000;
      5'b11100 : memoutb4 = 18'b010000101101110000;
      5'b11101 : memoutb4 = 18'b010011110000010000;
      5'b11110 : memoutb4 = 18'b010110110010110000;
      5'b11111 : memoutb4 = 18'b011001110101010000;
      default : memoutb4 = 18'b011001110101010000;
    endcase
  end

  assign mem_addrb5 = {delay_pipeline_5[3], delay_pipeline_5[2], delay_pipeline_5[1], delay_pipeline_5[0], filter_in_5};

  always @(mem_addrb5)
  begin
    case(mem_addrb5)
      5'b00000 : memoutb5 = 18'b000000000000000000;
      5'b00001 : memoutb5 = 18'b000011000010100000;
      5'b00010 : memoutb5 = 18'b000110000101000000;
      5'b00011 : memoutb5 = 18'b001001000111100000;
      5'b00100 : memoutb5 = 18'b000111100110010000;
      5'b00101 : memoutb5 = 18'b001010101000110000;
      5'b00110 : memoutb5 = 18'b001101101011010000;
      5'b00111 : memoutb5 = 18'b010000101101110000;
      5'b01000 : memoutb5 = 18'b000110000101000000;
      5'b01001 : memoutb5 = 18'b001001000111100000;
      5'b01010 : memoutb5 = 18'b001100001010000000;
      5'b01011 : memoutb5 = 18'b001111001100100000;
      5'b01100 : memoutb5 = 18'b001101101011010000;
      5'b01101 : memoutb5 = 18'b010000101101110000;
      5'b01110 : memoutb5 = 18'b010011110000010000;
      5'b01111 : memoutb5 = 18'b010110110010110000;
      5'b10000 : memoutb5 = 18'b000011000010100000;
      5'b10001 : memoutb5 = 18'b000110000101000000;
      5'b10010 : memoutb5 = 18'b001001000111100000;
      5'b10011 : memoutb5 = 18'b001100001010000000;
      5'b10100 : memoutb5 = 18'b001010101000110000;
      5'b10101 : memoutb5 = 18'b001101101011010000;
      5'b10110 : memoutb5 = 18'b010000101101110000;
      5'b10111 : memoutb5 = 18'b010011110000010000;
      5'b11000 : memoutb5 = 18'b001001000111100000;
      5'b11001 : memoutb5 = 18'b001100001010000000;
      5'b11010 : memoutb5 = 18'b001111001100100000;
      5'b11011 : memoutb5 = 18'b010010001111000000;
      5'b11100 : memoutb5 = 18'b010000101101110000;
      5'b11101 : memoutb5 = 18'b010011110000010000;
      5'b11110 : memoutb5 = 18'b010110110010110000;
      5'b11111 : memoutb5 = 18'b011001110101010000;
      default : memoutb5 = 18'b011001110101010000;
    endcase
  end

  assign mem_addrb6 = {delay_pipeline_6[3], delay_pipeline_6[2], delay_pipeline_6[1], delay_pipeline_6[0], filter_in_6};

  always @(mem_addrb6)
  begin
    case(mem_addrb6)
      5'b00000 : memoutb6 = 18'b000000000000000000;
      5'b00001 : memoutb6 = 18'b000011000010100000;
      5'b00010 : memoutb6 = 18'b000110000101000000;
      5'b00011 : memoutb6 = 18'b001001000111100000;
      5'b00100 : memoutb6 = 18'b000111100110010000;
      5'b00101 : memoutb6 = 18'b001010101000110000;
      5'b00110 : memoutb6 = 18'b001101101011010000;
      5'b00111 : memoutb6 = 18'b010000101101110000;
      5'b01000 : memoutb6 = 18'b000110000101000000;
      5'b01001 : memoutb6 = 18'b001001000111100000;
      5'b01010 : memoutb6 = 18'b001100001010000000;
      5'b01011 : memoutb6 = 18'b001111001100100000;
      5'b01100 : memoutb6 = 18'b001101101011010000;
      5'b01101 : memoutb6 = 18'b010000101101110000;
      5'b01110 : memoutb6 = 18'b010011110000010000;
      5'b01111 : memoutb6 = 18'b010110110010110000;
      5'b10000 : memoutb6 = 18'b000011000010100000;
      5'b10001 : memoutb6 = 18'b000110000101000000;
      5'b10010 : memoutb6 = 18'b001001000111100000;
      5'b10011 : memoutb6 = 18'b001100001010000000;
      5'b10100 : memoutb6 = 18'b001010101000110000;
      5'b10101 : memoutb6 = 18'b001101101011010000;
      5'b10110 : memoutb6 = 18'b010000101101110000;
      5'b10111 : memoutb6 = 18'b010011110000010000;
      5'b11000 : memoutb6 = 18'b001001000111100000;
      5'b11001 : memoutb6 = 18'b001100001010000000;
      5'b11010 : memoutb6 = 18'b001111001100100000;
      5'b11011 : memoutb6 = 18'b010010001111000000;
      5'b11100 : memoutb6 = 18'b010000101101110000;
      5'b11101 : memoutb6 = 18'b010011110000010000;
      5'b11110 : memoutb6 = 18'b010110110010110000;
      5'b11111 : memoutb6 = 18'b011001110101010000;
      default : memoutb6 = 18'b011001110101010000;
    endcase
  end

  assign mem_addrb7 = {delay_pipeline_7[3], delay_pipeline_7[2], delay_pipeline_7[1], delay_pipeline_7[0], filter_in_7};

  always @(mem_addrb7)
  begin
    case(mem_addrb7)
      5'b00000 : memoutb7 = 18'b000000000000000000;
      5'b00001 : memoutb7 = 18'b000011000010100000;
      5'b00010 : memoutb7 = 18'b000110000101000000;
      5'b00011 : memoutb7 = 18'b001001000111100000;
      5'b00100 : memoutb7 = 18'b000111100110010000;
      5'b00101 : memoutb7 = 18'b001010101000110000;
      5'b00110 : memoutb7 = 18'b001101101011010000;
      5'b00111 : memoutb7 = 18'b010000101101110000;
      5'b01000 : memoutb7 = 18'b000110000101000000;
      5'b01001 : memoutb7 = 18'b001001000111100000;
      5'b01010 : memoutb7 = 18'b001100001010000000;
      5'b01011 : memoutb7 = 18'b001111001100100000;
      5'b01100 : memoutb7 = 18'b001101101011010000;
      5'b01101 : memoutb7 = 18'b010000101101110000;
      5'b01110 : memoutb7 = 18'b010011110000010000;
      5'b01111 : memoutb7 = 18'b010110110010110000;
      5'b10000 : memoutb7 = 18'b000011000010100000;
      5'b10001 : memoutb7 = 18'b000110000101000000;
      5'b10010 : memoutb7 = 18'b001001000111100000;
      5'b10011 : memoutb7 = 18'b001100001010000000;
      5'b10100 : memoutb7 = 18'b001010101000110000;
      5'b10101 : memoutb7 = 18'b001101101011010000;
      5'b10110 : memoutb7 = 18'b010000101101110000;
      5'b10111 : memoutb7 = 18'b010011110000010000;
      5'b11000 : memoutb7 = 18'b001001000111100000;
      5'b11001 : memoutb7 = 18'b001100001010000000;
      5'b11010 : memoutb7 = 18'b001111001100100000;
      5'b11011 : memoutb7 = 18'b010010001111000000;
      5'b11100 : memoutb7 = 18'b010000101101110000;
      5'b11101 : memoutb7 = 18'b010011110000010000;
      5'b11110 : memoutb7 = 18'b010110110010110000;
      5'b11111 : memoutb7 = 18'b011001110101010000;
      default : memoutb7 = 18'b011001110101010000;
    endcase
  end

  assign mem_addrb8 = {delay_pipeline_8[3], delay_pipeline_8[2], delay_pipeline_8[1], delay_pipeline_8[0], filter_in_8};

  always @(mem_addrb8)
  begin
    case(mem_addrb8)
      5'b00000 : memoutb8 = 18'b000000000000000000;
      5'b00001 : memoutb8 = 18'b000011000010100000;
      5'b00010 : memoutb8 = 18'b000110000101000000;
      5'b00011 : memoutb8 = 18'b001001000111100000;
      5'b00100 : memoutb8 = 18'b000111100110010000;
      5'b00101 : memoutb8 = 18'b001010101000110000;
      5'b00110 : memoutb8 = 18'b001101101011010000;
      5'b00111 : memoutb8 = 18'b010000101101110000;
      5'b01000 : memoutb8 = 18'b000110000101000000;
      5'b01001 : memoutb8 = 18'b001001000111100000;
      5'b01010 : memoutb8 = 18'b001100001010000000;
      5'b01011 : memoutb8 = 18'b001111001100100000;
      5'b01100 : memoutb8 = 18'b001101101011010000;
      5'b01101 : memoutb8 = 18'b010000101101110000;
      5'b01110 : memoutb8 = 18'b010011110000010000;
      5'b01111 : memoutb8 = 18'b010110110010110000;
      5'b10000 : memoutb8 = 18'b000011000010100000;
      5'b10001 : memoutb8 = 18'b000110000101000000;
      5'b10010 : memoutb8 = 18'b001001000111100000;
      5'b10011 : memoutb8 = 18'b001100001010000000;
      5'b10100 : memoutb8 = 18'b001010101000110000;
      5'b10101 : memoutb8 = 18'b001101101011010000;
      5'b10110 : memoutb8 = 18'b010000101101110000;
      5'b10111 : memoutb8 = 18'b010011110000010000;
      5'b11000 : memoutb8 = 18'b001001000111100000;
      5'b11001 : memoutb8 = 18'b001100001010000000;
      5'b11010 : memoutb8 = 18'b001111001100100000;
      5'b11011 : memoutb8 = 18'b010010001111000000;
      5'b11100 : memoutb8 = 18'b010000101101110000;
      5'b11101 : memoutb8 = 18'b010011110000010000;
      5'b11110 : memoutb8 = 18'b010110110010110000;
      5'b11111 : memoutb8 = 18'b011001110101010000;
      default : memoutb8 = 18'b011001110101010000;
    endcase
  end

  //  Shift and add the LUT results to compute the scaled accumulated sum

  assign unaryminus_temp = (memoutb8==18'b100000000000000000) ? $signed({1'b0, memoutb8}) : -memoutb8;
  assign lut_msb = unaryminus_temp[17:0];

  assign add_signext = $signed({memoutb2[17:0], 1'b0});
  assign add_signext_1 = $signed({{1{memoutb1[17]}}, memoutb1});
  assign memsum1_1 = add_signext + add_signext_1;

  assign add_signext_2 = $signed({memoutb4[17:0], 1'b0});
  assign add_signext_3 = $signed({{1{memoutb3[17]}}, memoutb3});
  assign memsum1_2 = add_signext_2 + add_signext_3;

  assign add_signext_4 = $signed({memoutb6[17:0], 1'b0});
  assign add_signext_5 = $signed({{1{memoutb5[17]}}, memoutb5});
  assign memsum1_3 = add_signext_4 + add_signext_5;

  assign add_signext_6 = $signed({lut_msb[17:0], 1'b0});
  assign add_signext_7 = $signed({{1{memoutb7[17]}}, memoutb7});
  assign memsum1_4 = add_signext_6 + add_signext_7;

  assign memsumshft2_1 = memsum1_2;

  assign add_signext_8 = $signed({memsumshft2_1[19:0], 2'b00});
  assign add_signext_9 = $signed({{2{memsum1_1[19]}}, memsum1_1});
  assign memsum2_1 = add_signext_8 + add_signext_9;

  assign memsumshft2_2 = memsum1_4;

  assign add_signext_10 = $signed({memsumshft2_2[19:0], 2'b00});
  assign add_signext_11 = $signed({{2{memsum1_3[19]}}, memsum1_3});
  assign memsum2_2 = add_signext_10 + add_signext_11;

  assign memsumshft3_1 = memsum2_2;

  assign add_signext_12 = $signed({memsumshft3_1[22:0], 4'b0000});
  assign add_signext_13 = $signed({{4{memsum2_1[22]}}, memsum2_1});
  assign memsum3_1 = add_signext_12 + add_signext_13;

  assign output_da = memsum3_1;

  assign output_typeconvert = (output_da[26:0] + {output_da[19], {18{~output_da[19]}}})>>>19;

  always @ ( posedge clk)
    begin: Output_Register_process
      if (syn_rst == 1'b1) begin
        output_register <= 0;
      end
      else begin
        if (clk_enable == 1'b1) begin
          output_register <= output_typeconvert;
        end
      end
    end // Output_Register_process

  // Assignment Statements
  assign filter_out = output_register;
endmodule  // fir_da
