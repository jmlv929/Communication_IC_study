01 module cic_comb #(parameter idw = 8, odw = 9, N = 15)(
02     input   clk,
03     input   reset_n,
04     input   in_dv,
05     input   signed [idw-1:0] data_in,
06     output  reg signed [odw-1:0] data_out );
07 reg signed [idw-1:0] data_reg[N-1:0];
08 integer i;
09 always @(posedge clk)
10   if (!reset_n) begin
11     for (i=0;i<N;i=i+1)
12         data_reg[i] <= 'h0;
13     data_out <= 'h0;
14   end
15   else if (in_dv) begin
16     data_reg[0] <= data_in;
17     for (i=1;i<N;i=i+1) //移位寄存器，用于保存历史数据
18         data_reg[i] <= data_reg[i-1];
19     data_out <= data_in - data_reg[N-1]; //减法只发生在相隔N个点之间
20   end
21 
22 endmodule

