2 function [7:0] next_c8;
3 input [7:0] crc;
4 input B;
5 begin //h03为CRC-8的本征多项式
6   next_c8 = {crc[6:0],1'b0}^({8{(crc[7]^B)}} & 8'h03 );
7 end
8 endfunction
 
 
01 function [31:0] next_c8_ge; //
02   input [M-1:0] data;
03   input [7:0] crc;
04   integer  i;
05   begin
06     next_c8_ge = crc;
07     for(i=0; i<M; i=i+1) begin //并行化展开的关键，此处直接并行8次
08          next_c8_ge = next_c8(next_8_ge,data[M-i-1]);
09     end
10   end
11 endfunction
12


32   d = Data;
33   c = crc;
35   newcrc[0] = d[7]^d[6]^d[0]^c[0]^c[6]^c[7];
36   newcrc[1] = d[6]^d[1]^d[0]^c[0]^c[1]^c[6];
37   newcrc[2] = d[6]^d[2]^d[1]^d[0]^c[0]^c[1]^c[2]^c[6];
38   newcrc[3] = d[7]^d[3]^d[2]^d[1]^c[1]^c[2]^c[3]^c[7];
39   newcrc[4] = d[4]^d[3]^d[2]^c[2]^c[3]^c[4];
40   newcrc[5] = d[5]^d[4]^d[3]^c[3]^c[4]^c[5];
41   newcrc[6] = d[6]^d[5]^d[4]^c[4]^c[5]^c[6];
42   newcrc[7] = d[7]^d[6]^d[5]^c[5]^c[6]^c[7];
43   nextCRC8_D8 = newcrc;


21 module CRC16_D8;
23   // polynomial: (0 2 15 16)
24   // data width: 8
25   // convention: the first serial bit is D[7]
26   function [15:0] nextCRC16_D8;
28     input [7:0] Data;
29     input [15:0] crc;
30     reg [7:0] d;
31     reg [15:0] c;
32     reg [15:0] newcrc;
33   begin
34     d = Data;
35     c = crc;
37     newcrc[0] = d[7]^d[6]^d[5]^d[4]^d[3]^d[2]^d[1]^d[0]^c[8] 
38                ^c[9]^c[10]^c[11]^c[12]^c[13]^c[14]^c[15];
39     newcrc[1] = d[7]^d[6]^d[5]^d[4]^d[3]^d[2]^d[1]^c[9]^c[10]
40                ^c[11]^c[12]^c[13]^c[14]^c[15];
41     newcrc[2] = d[1]^d[0]^c[8]^c[9];
42     newcrc[3] = d[2]^d[1]^c[9]^c[10];
43     newcrc[4] = d[3]^d[2]^c[10]^c[11];
44     newcrc[5] = d[4]^d[3]^c[11]^c[12];
45     newcrc[6] = d[5]^d[4]^c[12]^c[13];
46     newcrc[7] = d[6]^d[5]^c[13]^c[14];
47     newcrc[8] = d[7]^d[6]^c[0]^c[14]^c[15];
48     newcrc[9] = d[7]^c[1]^c[15];
49     newcrc[10] = c[2];
50     newcrc[11] = c[3];
51     newcrc[12] = c[4];
52     newcrc[13] = c[5];
53     newcrc[14] = c[6];
54     newcrc[15] = d[7]^d[6]^d[5]^d[4]^d[3]^d[2]^d[1]^d[0]^c[7]
55                 ^c[8]^c[9]^c[10]^c[11]^c[12]^c[13]^c[14]^c[15];
57     nextCRC16_D8 = newcrc;
58   end
59   endfunction
60 endmodule


 2 // CRC module for data[7:0] ,   crc[4:0]=1+x^2+x^5;
 4 module crc(
 5   input [7:0] data_in,
 6   input crc_en,
 7   output [4:0] crc_out,
 8   input rst,
 9   input clk);
11   reg [4:0] lfsr_q,lfsr_c;
13   assign crc_out = lfsr_q;
15   always @(*) begin
16     lfsr_c[0] = lfsr_q[0]^lfsr_q[2]^lfsr_q[3]^data_in[0]^data_in[3]^data_in[
17                 5]^data_in[6];
18     lfsr_c[1] = lfsr_q[1]^lfsr_q[3]^lfsr_q[4]^data_in[1]^data_in[4]^data_in[
19                 6]^data_in[7];
20     lfsr_c[2] = lfsr_q[0]^lfsr_q[3]^lfsr_q[4]^data_in[0]^data_in[2]^data_in[
21                 3]^data_in[6]^data_in[7];
22     lfsr_c[3] = lfsr_q[0]^lfsr_q[1]^lfsr_q[4]^data_in[1]^data_in[3]^data_in[
23                 4]^data_in[7];
24     lfsr_c[4] = lfsr_q[1]^lfsr_q[2]^data_in[2]^data_in[4]^data_in[5];
25   end // always
26 
27   always @(posedge clk, posedge rst) begin
28     if(rst) begin
29       lfsr_q <= {5{1'b1}};
30     end
31     else begin
32       lfsr_q <= crc_en ? lfsr_c : lfsr_q;
33     end
34   end // always
35 endmodule // crc


423 generate
424   genvar i;
425   for(i = 0;i < 64;i = i + 1) // 并行例化实现，如果部分并行就要设置控制逻辑
426   begin:gen_acs
427     dec_viterbi_acs u_acs
428     ( // VITERBI_TYPE表示式RCPC(2,1,7)还是(3,1,7)
429       .VITERBI_TYPE         (VITERBI_TYPE                        ),
430       // RCPC的通用系数表示，这是一个通用性设计，输入多项式系数即可译码
431       .RCPC217_POLY1        (RCPC217_POLY1                       ),
432       .RCPC217_POLY2        (RCPC217_POLY2                       ),
433       .RCPC317_POLY1        (RCPC317_POLY1                       ),
434       .RCPC317_POLY2        (RCPC317_POLY2                       ),
435       .RCPC317_POLY3        (RCPC317_POLY3                       ),
436      // 当前ACS计算是哪个单元
437       .STATE                (i                                   ),
438       .DIN0                 (din0                                ), //g0
439       .DIN1                 (din1                                ), //g1
440       .DIN2                 (din2                                ), //g2
441       .PRESTATE0_DISTANCESUM(reg_distancesum_state[{1'b0,i[5:1]}]),
442       .PRESTATE1_DISTANCESUM(reg_distancesum_state[{1'b1,i[5:1]}]),
443       // 输出分支度量
444       .DISTANCESUM0         (distancesum0_state[i]               ),
445       .DISTANCESUM1         (distancesum1_state[i]               ),
446                                                                    
447       .DISTANCESUM          (distancesum_state[i]                ),
448                                                                    
449       .ACSBIT               (acsbit_state[i]                     )
450     );
451   end
452 endgenerate


206 always @(*)
207 begin
208   if(~VITERBI_TYPE) //viterbi217
209   begin  // 计算两个分支的累加和
210     DISTANCESUM0 = PRESTATE0_DISTANCESUM + (prestate0_delta0_square + 
211                    prestate0_delta1_square);
212     DISTANCESUM1 = PRESTATE1_DISTANCESUM + (prestate1_delta0_square + 
213                    prestate1_delta1_square);
214   end
215   else //viterbi317
216   begin
217     DISTANCESUM0 = PRESTATE0_DISTANCESUM + (prestate0_delta0_square + 
218                    prestate0_delta1_square + prestate0_delta2_square);
219     DISTANCESUM1 = PRESTATE1_DISTANCESUM + (prestate1_delta0_square + 
220                    prestate1_delta1_square + prestate1_delta2_square);
221   end
222 end
223  // 加比选以及存储由哪个状态跳转而来，方便回溯
224 assign DISTANCESUM = (DISTANCESUM0 < DISTANCESUM1)? DISTANCESUM0:
225                      DISTANCESUM1;
227 assign ACSBIT = (DISTANCESUM0 <= DISTANCESUM1)? 1'b0:1'b1;

