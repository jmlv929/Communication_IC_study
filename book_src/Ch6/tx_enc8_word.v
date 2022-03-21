01 module tx_enc8 ( // input
02 input CLK_40,
03 input RST_X,
04 input VALID,
05 input SYN_RST,
06 input [7:0] DATA_IN,
07 output reg [15:0] DATA_OUT);
08
09 reg  [5:0] r_enc0;
10 wire [5:0] r_enc1,r_enc2,r_enc3,r_enc4,r_enc5,r_enc6,r_enc7,r_enc8;
11 wire [15:0]code;
12
13 assign r_enc1 = {DATA_IN[0], r_enc0[5:1]};
14 assign r_enc2 = {DATA_IN[1], r_enc1[5:1]};
15 assign r_enc3 = {DATA_IN[2], r_enc2[5:1]};
16 assign r_enc4 = {DATA_IN[3], r_enc3[5:1]};
17 assign r_enc5 = {DATA_IN[4], r_enc4[5:1]};
18 assign r_enc6 = {DATA_IN[5], r_enc5[5:1]};
19 assign r_enc7 = {DATA_IN[6], r_enc6[5:1]};
20 assign r_enc8 = {DATA_IN[7], r_enc7[5:1]};
21
22 assign code[ 0]=DATA_IN[0]^r_enc0[4]^r_enc0[3]^r_enc0[0]^r_enc0[1];
23 assign code[ 2]=DATA_IN[1]^r_enc1[4]^r_enc1[3]^r_enc1[0]^r_enc1[1];
24 assign code[ 4]=DATA_IN[2]^r_enc2[4]^r_enc2[3]^r_enc2[0]^r_enc2[1];
25 assign code[ 6]=DATA_IN[3]^r_enc3[4]^r_enc3[3]^r_enc3[0]^r_enc3[1];
26 assign code[ 8]=DATA_IN[4]^r_enc4[4]^r_enc4[3]^r_enc4[0]^r_enc4[1];
27 assign code[10]=DATA_IN[5]^r_enc5[4]^r_enc5[3]^r_enc5[0]^r_enc5[1];
28 assign code[12]=DATA_IN[6]^r_enc6[4]^r_enc6[3]^r_enc6[0]^r_enc6[1];
29 assign code[14]=DATA_IN[7]^r_enc7[4]^r_enc7[3]^r_enc7[0]^r_enc7[1];
30
31 assign code[ 1]=DATA_IN[0]^r_enc0[4]^r_enc0[3]^r_enc0[0]^r_enc0[5];
32 assign code[ 3]=DATA_IN[1]^r_enc1[4]^r_enc1[3]^r_enc1[0]^r_enc1[5];
33 assign code[ 5]=DATA_IN[2]^r_enc2[4]^r_enc2[3]^r_enc2[0]^r_enc2[5];
34 assign code[ 7]=DATA_IN[3]^r_enc3[4]^r_enc3[3]^r_enc3[0]^r_enc3[5];
35 assign code[ 9]=DATA_IN[4]^r_enc4[4]^r_enc4[3]^r_enc4[0]^r_enc4[5];
36 assign code[11]=DATA_IN[5]^r_enc5[4]^r_enc5[3]^r_enc5[0]^r_enc5[5];
37 assign code[13]=DATA_IN[6]^r_enc6[4]^r_enc6[3]^r_enc6[0]^r_enc6[5];
38 assign code[15]=DATA_IN[7]^r_enc7[4]^r_enc7[3]^r_enc7[0]^r_enc7[5];
39
40 always @(posedge CLK_40 or negedge RST_X)
41   if(!RST_X)begin
42     r_enc0   <= 6'd0;
43     DATA_OUT <= 16'd0;
44   end
45   else if(SYN_RST==1'b1)begin
46     r_enc0   <= 6'd0;
47     DATA_OUT <= 16'd0;
48   end
49   else if(VALID==1'b1)begin
50     r_enc0   <= r_enc8;
51     DATA_OUT <= code;
52   end
53
54 endmodule
55