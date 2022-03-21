01 module RanGen(
02   input      rst_n,  // reset signal
03   input      clk,    //clock signal
04   input      load,   //load seed to rand_num
05   input [7:0]rnd_seed,//随机数种子
06   output[7:0]lsfr_rand //用于dither的随机数输出，目前只用3bit
07 );
08 reg[7:0]lsfr;
09 assign lsfr_rand=lsfr;
10 //16bit LSFR只是寄存器长度边长，但代码结构不变
11 always@(posedge clk or negedge rst_n)
12   if(!rst_n)
13     lsfr  <=8'b1111_1111;
14   else if(load)
15     lsfr <=rnd_seed;  
16   else begin
17     lsfr[0] <= lsfr[7];
18     lsfr[1] <= lsfr[0];
19     lsfr[2] <= lsfr[1];
20     lsfr[3] <= lsfr[2];
21     lsfr[4] <= lsfr[3]^lsfr[7];
22     lsfr[5] <= lsfr[4]^lsfr[7];
23     lsfr[6] <= lsfr[5]^lsfr[7];
24     lsfr[7] <= lsfr[6];
25   end
26 endmodule
