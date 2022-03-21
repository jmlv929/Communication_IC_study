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
`define log2(n)   ((n) <= (1<<0) ? 0 : (n) <= (1<<1) ? 1 :\
                   (n) <= (1<<2) ? 2 : (n) <= (1<<3) ? 3 :\
                   (n) <= (1<<4) ? 4 : (n) <= (1<<5) ? 5 :\
                   (n) <= (1<<6) ? 6 : (n) <= (1<<7) ? 7 :\
                   (n) <= (1<<8) ? 8 : (n) <= (1<<9) ? 9 :\
                   (n) <= (1<<10) ? 10 : (n) <= (1<<11) ? 11 :\
                   (n) <= (1<<12) ? 12 : (n) <= (1<<13) ? 13 :\
                   (n) <= (1<<14) ? 14 : (n) <= (1<<15) ? 15 :\
                   (n) <= (1<<16) ? 16 : (n) <= (1<<17) ? 17 :\
                   (n) <= (1<<18) ? 18 : (n) <= (1<<19) ? 19 :\
                   (n) <= (1<<20) ? 20 : (n) <= (1<<21) ? 21 :\
                   (n) <= (1<<22) ? 22 : (n) <= (1<<23) ? 23 :\
                   (n) <= (1<<24) ? 24 : (n) <= (1<<25) ? 25 :\
                   (n) <= (1<<26) ? 26 : (n) <= (1<<27) ? 27 :\
                   (n) <= (1<<28) ? 28 : (n) <= (1<<29) ? 29 :\
                   (n) <= (1<<30) ? 30 : (n) <= (1<<31) ? 31 : 32) 

module fir_da #(parameter N_taps=9,parameter BIT_WIDTH=16)(
  input   clk, 
  input   clk_enable, 
  input   syn_rst, 
  input   signed [BIT_WIDTH-1:0] filter_in, //sfix8_En7
  output reg signed [BIT_WIDTH-1:0] filter_out); //sfix8_En7

localparam DA_WIDTH =BIT_WIDTH+`log2(N_taps);
localparam SUM_WIDTH=BIT_WIDTH+`log2(BIT_WIDTH)+`log2(N_taps);

reg  signed [N_taps   -1:0] delay_pipeline[BIT_WIDTH-1:0];
wire signed [DA_WIDTH -1:0] DA_data[BIT_WIDTH-1:0];
wire signed [SUM_WIDTH-1:0] sum[BIT_WIDTH:0];

assign sum[0]=0;
integer j;
generate
  genvar i;
  for(i=0;i<BIT_WIDTH;i=i+1) begin : BIT_WIDTH_1bit_LUT
	    always @( posedge clk)
	    if (syn_rst == 1'b1) begin
	   		for(j=0;j<N_taps;j=j+1) begin : bit_matrix_intial
	        delay_pipeline[i][j] <= 1'b0;
	      end
		  end else if (clk_enable == 1'b1) begin
	      delay_pipeline[i][0] <= filter_in[i];
	    	for(j=1;j<N_taps;j=j+1) begin : bit_matrix
		      delay_pipeline[i][j] <= delay_pipeline[i][j-1];
		    end
	    end
	    
		DA_ROM #(N_taps,DA_WIDTH)U_bit(.addr(delay_pipeline[i]),.data(DA_data[i]));
	  assign sum[i+1]=sum[i]+(DA_data[i]<<<i);
  end
endgenerate

always @ ( posedge clk)
  if (syn_rst == 1'b1)
    filter_out <= 0;
  else if (clk_enable == 1'b1)
    filter_out <= sum[N_taps][SUM_WIDTH-1:SUM_WIDTH-BIT_WIDTH];

endmodule

module DA_ROM #(parameter N_taps=5,parameter ROM_WDITH=18)(
  input [N_taps-1:0]addr,
  output reg [ROM_WDITH-1:0] data
);
  always @(addr)
  begin
    case(addr)
      5'b00000 : data = 18'b000000000000000000;
      5'b00001 : data = 18'b000011000010100000;
      5'b00010 : data = 18'b000110000101000000;
      5'b00011 : data = 18'b001001000111100000;
      5'b00100 : data = 18'b000111100110010000;
      5'b00101 : data = 18'b001010101000110000;
      5'b00110 : data = 18'b001101101011010000;
      5'b00111 : data = 18'b010000101101110000;
      5'b01000 : data = 18'b000110000101000000;
      5'b01001 : data = 18'b001001000111100000;
      5'b01010 : data = 18'b001100001010000000;
      5'b01011 : data = 18'b001111001100100000;
      5'b01100 : data = 18'b001101101011010000;
      5'b01101 : data = 18'b010000101101110000;
      5'b01110 : data = 18'b010011110000010000;
      5'b01111 : data = 18'b010110110010110000;
      5'b10000 : data = 18'b000011000010100000;
      5'b10001 : data = 18'b000110000101000000;
      5'b10010 : data = 18'b001001000111100000;
      5'b10011 : data = 18'b001100001010000000;
      5'b10100 : data = 18'b001010101000110000;
      5'b10101 : data = 18'b001101101011010000;
      5'b10110 : data = 18'b010000101101110000;
      5'b10111 : data = 18'b010011110000010000;
      5'b11000 : data = 18'b001001000111100000;
      5'b11001 : data = 18'b001100001010000000;
      5'b11010 : data = 18'b001111001100100000;
      5'b11011 : data = 18'b010010001111000000;
      5'b11100 : data = 18'b010000101101110000;
      5'b11101 : data = 18'b010011110000010000;
      5'b11110 : data = 18'b010110110010110000;
      5'b11111 : data = 18'b011001110101010000;
      default : data = 18'b011001110101010000;
    endcase
  end
endmodule
