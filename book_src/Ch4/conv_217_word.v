01 `timescale 1 ns / 1 ps // Unrolled LFSR (n,k,m)
02 module conv_217 #(parameter m = 2,parameter n = 7)(
03   input clk,rst_n,ena,
04   input din,    // bit 0 is to be sent first
05   output[m-1:0] cout);
06   
07 wire [n-1:0] g[m-1:0]; //生成多项式系数，需要进行高低位转置
08 assign g[0][n-1:0]=7'b110_110_1;//7'b1_011_011;
09 assign g[1][n-1:0]=7'b100_111_1;//7'b1_111_001;
10 
11 reg [n-1:0] conv_buf; // 用于缓存的buffer
12 genvar i;
13 generate
14   for (i=0; i<m; i=i+1) begin : lp // 用于卷积相乘以及缩位异或操作
15     assign cout[i] = ^(g[i][n-1:0]&conv_buf[n-1:0]);    
16   end
17 endgenerate
18 //assign cout[0]=^(g[0][n-1:0]&conv_buf[n-1:0]);
19 //assign cout[1]=^(g[1][n-1:0]&conv_buf[n-1:0]);
20 
21 // din buffer with length n
22 always @(posedge clk or negedge rst_n)
23   if (!rst_n)
24     conv_buf <= 0;
25   else if (ena) //输入缓存buff
26     conv_buf[n-1:0] <= {conv_buf[n-2:0],din};
27 endmodule
28