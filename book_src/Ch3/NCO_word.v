01 module NCO #( parameter DATA_WIDTH=28)(
02   input                   clk,
03   input                   rst_n,
04   input                   ena,
05   input  [DATA_WIDTH-1:0] fre_chtr,
06   input  [DATA_WIDTH-1:0] pha_chtr,
07   output [DATA_WIDTH-1:0] sin_out,
08   output [DATA_WIDTH-1:0] cos_out,
09   output [DATA_WIDTH-1:0] eps_out);
11 reg [DATA_WIDTH-1:0] phase_in;
12 reg [DATA_WIDTH-1:0] fre_chtr_reg;
13 
14 always@(posedge clk or negedge rst_n)
15   if(!rst_n)
16     fre_chtr_reg<=28'd0;
17   else if(ena)
18     fre_chtr_reg<=fre_chtr+fre_chtr_reg;   
19 
20 always@(posedge clk or negedge rst_n)
21   if(!rst_n)
22     phase_in<=28'd0;
23   else if(ena) //相位累加器
24     phase_in<=pha_chtr+fre_chtr_reg;   
25  //波形存储，如果将sincos替换为其它波形，就是DDS
26 sincos u_sincos(.clk(clk),.rst_n(rst_n),.ena(ena),.phase_in(
27       phase_in),.sin_out(sin_out),.cos_out(cos_out), eps(eps_out));.
28 
29 endmodule 
