
module duc(
   input         Clk,
   input         Rst,
 
   input [31:0]  FreqOffset,
   input [11:0]  AmpI,
   input [11:0]  AmpQ,

   input [11:0]  Baseband_I,
   input [11:0]  Baseband_Q,
   
   output [15:0] IF_Out_I,
   output [15:0] IF_Out_Q
);  
   
   wire [15:0]   MulInI;
   wire [12:0]   HAmpI;
   wire [28:0]   MulOutI;
   wire [15:0]   MulInQ;
   wire [12:0]   HAmpQ;
   wire [28:0]   MulOutQ;
   
   wire [13:0]   sin;
   wire [13:0]   cos;
   reg [31:0]    NCOCnt;
   
   assign MulInI = {Baseband_I, 4'b0000};
   assign MulInQ = {Baseband_Q, 4'b0000};
   assign HAmpI = {1'b0, AmpI};
   assign HAmpQ = {1'b0, AmpQ};
   
   mul_amp amp_mul_I(.a_in(MulInI), .b_in(HAmpI), .carryin_in(1'b0), .clk_in(Clk), .p_out(MulOutI));
   mul_amp amp_mul_Q(.a_in(MulInQ), .b_in(HAmpQ), .carryin_in(1'b0), .clk_in(Clk), .p_out(MulOutQ));
   
   always @(posedge Clk or posedge Rst)
      if (Rst == 1'b1)
         NCOCnt <= {32{1'b0}};
      else 
         NCOCnt <= NCOCnt + FreqOffset;
    
   nco_sinetab U_sintab(.theta(NCOCnt[31:22]), .clk(Clk), .sine(sin), .cosine(cos));
   
   IF_mixer NCO_mul(.clk(Clk), .in_en(1'b1), .i1(MulOutI[27:12]), .i2(cos), .q1(MulOutQ[27:12]), .q2(sin), .reres(IF_Out_I), .imres(IF_Out_Q));
   
endmodule
