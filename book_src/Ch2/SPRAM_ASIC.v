87 module SPRAM16X16K_ASIC(
88               Q,
89               CLK,
90               CEN,
91               WEN,
92               A,
93               D);
95   parameter Bits = 16;
96   parameter Word_Depth = 16384;
97   parameter Add_Width = 14;
99   output [Bits-1:0]  Q; // 数据输出
100   input             CLK; // 输入时钟
101   input             CEN; // SRAM 片选
102   input             WEN; // 写使能
103   input [Add_Width-1:0] A; // SRAM 地址
104   input [Bits-1:0]      D; // SRAM的数据输入
106  spram  #( //  这部分是替换的内容，用于FPGA的综合与仿真
108    .ADDR_WIDTH(Add_Width),.DATA_WIDTH(Bits) )
111    U_RAM (
113      .clk  (CLK )
114     ,.data (D)
115     ,.addr (A)
116     ,.we   (!WEN && !CEN)
117     ,.q    (Q)
118  );
121 endmodule
