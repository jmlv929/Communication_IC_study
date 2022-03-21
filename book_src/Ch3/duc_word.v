01 module duc(
02    input         Clk,
03    input         Rst,
04    input [31:0]  FreqOffset, // DDS的频率控制字，用于指定频率
05    input [11:0]  AmpI, // 发射I路幅度控制，用于功控
06    input [11:0]  AmpQ, // 发射Q路幅度控制，用于功控
07    input [11:0]  Baseband_I, // 发射基带I路信号，已经上插到中频速率
08    input [11:0]  Baseband_Q, // 发射基带Q路信号，已经上插到中频速率
09    output [15:0] IF_Out_I, // 发射中频I路信号
10    output [15:0] IF_Out_Q  // 发射中频Q路信号
11 );  
12  wire [15:0]   MulInI;
13  wire [12:0]   HAmpI;
14  wire [28:0]   MulOutI;
15  wire [15:0]   MulInQ;
16  wire [12:0]   HAmpQ;
17  wire [28:0]   MulOutQ;
18  wire [13:0]   sin;
19  wire [13:0]   cos;
20  reg [31:0]    NCOCnt;
21  
22  assign MulInI = {Baseband_I, 4'b0000};
23  assign MulInQ = {Baseband_Q, 4'b0000};
24  assign HAmpI = {1'b0, AmpI};
25  assign HAmpQ = {1'b0, AmpQ};
26  // 发射基带信号IQ两路的幅度调制，等效于Transmit power control(TPC)
27  mul_amp amp_mul_I(.a_in(MulInI),.b_in(HAmpI),.carryin_in(1'b0), .clk_in(Clk),.p_out(MulOutI));
28                    
29  mul_amp amp_mul_Q(.a_in(MulInQ),.b_in(HAmpQ),.carryin_in(1'b0), .clk_in(Clk),.p_out(MulOutQ));
30                    
31  // NCO的频率控制字，与ACC累加
32  always @(posedge Clk or posedge Rst)
33     if (Rst == 1'b1)
34        NCOCnt <= {32{1'b0}};
35     else 
36        NCOCnt <= NCOCnt + FreqOffset;
37   // NCO的频率控制字用于查表
38  nco_sin_tab U_sin_tab(.theta(NCOCnt[31:22]), .clk(Clk), .sine(
39                       sin), .cosine(cos));
40  // 中频混频实现，就是一个复数乘法实现
41  IF_mixer NCO_mul(.clk(Clk), .in_en(1'b1), .i1(MulOutI[27:12]), 
42                   .i2(cos), .q1(MulOutQ[27:12]), .q2(sin), .
43                   reres(IF_Out_I), .imres(IF_Out_Q));
44  
45 endmodule
46 