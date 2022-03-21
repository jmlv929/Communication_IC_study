1   module tx_fft_8 #(parameter IN_W   = 9, parameter OUT_W  = 12) (
2     input  [IN_W -1: 0] IN_I0,IN_I1,IN_I2,IN_I3,IN_I4,IN_I5,IN_I6,IN_I7,
3     input  [IN_W -1: 0] IN_Q0,IN_Q1,IN_Q2,IN_Q3,IN_Q4,IN_Q5,IN_Q6,IN_Q7,
4     output [OUT_W-1: 0] OUT_I0,OUT_I1,OUT_I2,OUT_I3,OUT_I4,OUT_I5,OUT_I6,OUT_I7,
5     output [OUT_W-1: 0] OUT_Q0,OUT_Q1,OUT_Q2,OUT_Q3,OUT_Q4,OUT_Q5,OUT_Q6,OUT_Q7
6   );
7   localparam MID_MUL_W = IN_W+2 ;
8   localparam P_SQRT2 = 9'd181;//9'h0b5 ;
9   wire [IN_W+1-1 : 0] tf0,tf1,tf2,tf3 ;
10  wire [IN_W+1-1 : 0] tg0,tg1,tg2,tg3 ;
11  wire [IN_W+2-1 : 0] tff0,tff1,tff2,tff3 ;
12  wire [IN_W+2-1 : 0] tgg0,tgg1,tgg2,tgg3 ;
13  wire [IN_W+1-1 : 0] tp0,tp1,tp2,tp3 ;
14  wire [IN_W+1-1 : 0] tq0,tq1,tq2,tq3 ;
15  wire [IN_W+2-1 : 0] tpp0,tpp1,tpp2,tpp3 ;
16  wire [IN_W+2-1 : 0] tqq0,tqq1,tqq2,tqq3 ;
17  wire [IN_W+3-1 : 0] t_i0,t_i1,t_i2,t_i3,t_i4,t_i5,t_i6,t_i7;
18  wire [IN_W+3-1 : 0] t_q0,t_q1,t_q2,t_q3,t_q4,t_q5,t_q6,t_q7;
19  wire [IN_W+3-1 : 0] twi1,twq1,twi3,twq3;
20  //2 point-FFT
21  assign tf0 =  {{{IN_I0[IN_W-1]}},IN_I0}+{{{IN_I2[IN_W-1]}},IN_I2};
22  assign tf1 =  {{{IN_I0[IN_W-1]}},IN_I0}-{{{IN_I2[IN_W-1]}},IN_I2};
23  assign tf2 =  {{{IN_I1[IN_W-1]}},IN_I1}+{{{IN_I3[IN_W-1]}},IN_I3};
24  assign tf3 =  {{{IN_I1[IN_W-1]}},IN_I1}-{{{IN_I3[IN_W-1]}},IN_I3};
25  assign tg0 =  {{{IN_Q0[IN_W-1]}},IN_Q0}+{{{IN_Q2[IN_W-1]}},IN_Q2};
26  assign tg1 =  {{{IN_Q0[IN_W-1]}},IN_Q0}-{{{IN_Q2[IN_W-1]}},IN_Q2};
27  assign tg2 =  {{{IN_Q1[IN_W-1]}},IN_Q1}+{{{IN_Q3[IN_W-1]}},IN_Q3}; 
28  assign tg3 =  {{{IN_Q1[IN_W-1]}},IN_Q1}-{{{IN_Q3[IN_W-1]}},IN_Q3};
29  assign tff0 = {tf0[IN_W],tf0}+{tf2[IN_W],tf2};
30  assign tff1 = {tf1[IN_W],tf1}+{tg3[IN_W],tg3};
31  assign tff2 = {tf0[IN_W],tf0}-{tf2[IN_W],tf2};
32  assign tff3 = {tf1[IN_W],tf1}-{tg3[IN_W],tg3};
33  assign tgg0 = {tg0[IN_W],tg0}+{tg2[IN_W],tg2};
34  assign tgg1 = {tg1[IN_W],tg1}-{tf3[IN_W],tf3};
35  assign tgg2 = {tg0[IN_W],tg0}-{tg2[IN_W],tg2};
36  assign tgg3 = {tg1[IN_W],tg1}+{tf3[IN_W],tf3};
37  assign tp0 = {{{IN_I4[IN_W-1]}},IN_I4}+{{{IN_I6[IN_W-1]}},IN_I6};
38  assign tp1 = {{{IN_I4[IN_W-1]}},IN_I4}-{{{IN_I6[IN_W-1]}},IN_I6};
39  assign tp2 = {{{IN_I5[IN_W-1]}},IN_I5}+{{{IN_I7[IN_W-1]}},IN_I7};
40  assign tp3 = {{{IN_I5[IN_W-1]}},IN_I5}-{{{IN_I7[IN_W-1]}},IN_I7};
41  assign tq0 = {{{IN_Q4[IN_W-1]}},IN_Q4}+{{{IN_Q6[IN_W-1]}},IN_Q6};
42  assign tq1 = {{{IN_Q4[IN_W-1]}},IN_Q4}-{{{IN_Q6[IN_W-1]}},IN_Q6};
43  assign tq2 = {{{IN_Q5[IN_W-1]}},IN_Q5}+{{{IN_Q7[IN_W-1]}},IN_Q7};
44  assign tq3 = {{{IN_Q5[IN_W-1]}},IN_Q5}-{{{IN_Q7[IN_W-1]}},IN_Q7};
45  assign tpp0 =  {tp0[IN_W],tp0}+{tp2[IN_W],tp2};//tp0[0]+tp2[0];
46  assign tpp1 =  {tp1[IN_W],tp1}+{tq3[IN_W],tq3};//tp1[0]+tq2[0];
47  assign tpp2 =  {tp0[IN_W],tp0}-{tp2[IN_W],tp2};//tp0[0]-tp2[0];
48  assign tpp3 =  {tp1[IN_W],tp1}-{tq3[IN_W],tq3};//tp1[0]-tq3[0];
49  assign tqq0 =  {tq0[IN_W],tq0}+{tq2[IN_W],tq2};//tq0[0]+tq2[0];
50  assign tqq1 =  {tq1[IN_W],tq1}-{tp3[IN_W],tp3};//tq1[0]-tp3[0];
51  assign tqq2 =  {tq0[IN_W],tq0}-{tq2[IN_W],tq2};//tq0[0]-tq2[0];
52  assign tqq3 =  {tq1[IN_W],tq1}+{tp3[IN_W],tp3};//tq1[0]+tp3[0];
53  // 本步骤已经除以2，所以后面定标需要注意!
54  wire[IN_W+3-1:0] mul_i1={tff1[IN_W+1],tff1}+{tgg1[IN_W+1],tgg1};
55  wire[IN_W+3-1:0] mul_q1={tgg1[IN_W+1],tgg1}-{tff1[IN_W+1],tff1};
56  wire[IN_W+3-1:0] mul_i3={tff3[IN_W+1],tff3}-{tgg3[IN_W+1],tgg3};
57  wire[IN_W+3-1:0] mul_q3={tff3[IN_W+1],tff3}+{tgg3[IN_W+1],tgg3};
58 
59  wire [MID_MUL_W-1:0] temp_mul_i1 = mul_i1[IN_W+3-1 : IN_W+3-MID_MUL_W];
60  wire [MID_MUL_W-1:0] temp_mul_q1 = mul_q1[IN_W+3-1 : IN_W+3-MID_MUL_W];
61  wire [MID_MUL_W-1:0] temp_mul_i3 = mul_i3[IN_W+3-1 : IN_W+3-MID_MUL_W];
62  wire [MID_MUL_W-1:0] temp_mul_q3 = mul_q3[IN_W+3-1 : IN_W+3-MID_MUL_W];
63 
64  wire signed[MID_MUL_W+9-1 : 0]temp_i1=P_SQRT2*temp_mul_i1;
65  wire signed[MID_MUL_W+9-1 : 0]temp_q1=P_SQRT2*temp_mul_q1;
66  wire signed[MID_MUL_W+9-1 : 0]temp_i3=P_SQRT2*temp_mul_i3;
67  wire signed[MID_MUL_W+9-1 : 0]temp_q3=P_SQRT2*temp_mul_q3;
68  //Get result with 2 times!
69  assign twi1= temp_i1[MID_MUL_W+9-2: MID_MUL_W+9-2-( IN_W+3 )+1];
70  assign twq1= temp_q1[MID_MUL_W+9-2: MID_MUL_W+9-2-( IN_W+3 )+1];
71  assign twi3= temp_i3[MID_MUL_W+9-2: MID_MUL_W+9-2-( IN_W+3 )+1];
72  assign twq3= temp_q3[MID_MUL_W+9-2: MID_MUL_W+9-2-( IN_W+3 )+1];
73  //now I finish the twiddle arimatic! now set the final result!
74  assign t_i0={tpp0[IN_W+2-1],tpp0[IN_W+2-1:0]}+{tff0[IN_W+2-1],tff0[IN_W+2-1:0]};
75  assign t_q0={tqq0[IN_W+2-1],tqq0[IN_W+2-1:0]}+{tgg0[IN_W+2-1],tgg0[IN_W+2-1:0]};
76  assign t_i4={tpp0[IN_W+2-1],tpp0[IN_W+2-1:0]}-{tff0[IN_W+2-1],tff0[IN_W+2-1:0]};
77  assign t_q4={tqq0[IN_W+2-1],tqq0[IN_W+2-1:0]}-{tgg0[IN_W+2-1],tgg0[IN_W+2-1:0]};
78  ////because of the Multply have introuduce a div 2 times!
79  assign t_i1={tpp1[IN_W+2-1],tpp1[IN_W+2-1 : 0]}+{twi1[( IN_W+3 )-1: 0]};
80  assign t_q1={tqq1[IN_W+2-1],tqq1[IN_W+2-1 : 0]}+{twq1[( IN_W+3 )-1: 0]};
81  assign t_i5={tpp1[IN_W+2-1],tpp1[IN_W+2-1 : 0]}-{twi1[( IN_W+3 )-1: 0]};
82  assign t_q5={tqq1[IN_W+2-1],tqq1[IN_W+2-1 : 0]}-{twq1[( IN_W+3 )-1: 0]};
83  assign t_i2={tpp2[IN_W+2-1],tpp2[IN_W+2-1:0]}+{tgg2[IN_W+2-1],tgg2[IN_W+2-1:0]};
84  assign t_q2={tqq2[IN_W+2-1],tqq2[IN_W+2-1:0]}-{tff2[IN_W+2-1],tff2[IN_W+2-1:0]};
85  assign t_i6={tpp2[IN_W+2-1],tpp2[IN_W+2-1:0]}-{tgg2[IN_W+2-1],tgg2[IN_W+2-1:0]};
86  assign t_q6={tqq2[IN_W+2-1],tqq2[IN_W+2-1:0]}+{tff2[IN_W+2-1],tff2[IN_W+2-1:0]};
87  assign t_i3={tpp3[IN_W+2-1],tpp3[IN_W+2-1 : 0]}-{twi3[( IN_W+3 )-1: 0]};
88  assign t_q3={tqq3[IN_W+2-1],tqq3[IN_W+2-1 : 0]}-{twq3[( IN_W+3 )-1: 0]};
89  assign t_i7={tpp3[IN_W+2-1],tpp3[IN_W+2-1 : 0]}+{twi3[( IN_W+3 )-1: 0]};
90  assign t_q7={tqq3[IN_W+2-1],tqq3[IN_W+2-1 : 0]}+{twq3[( IN_W+3 )-1: 0]};
91  //output signal assign
92  assign OUT_I0 =  t_i0[IN_W+3-1 : IN_W+3 -OUT_W];
93  assign OUT_I1 =  t_i1[IN_W+3-1 : IN_W+3 -OUT_W];
94  assign OUT_I2 =  t_i2[IN_W+3-1 : IN_W+3 -OUT_W];
95  assign OUT_I3 =  t_i3[IN_W+3-1 : IN_W+3 -OUT_W];
96  assign OUT_I4 =  t_i4[IN_W+3-1 : IN_W+3 -OUT_W];
97  assign OUT_I5 =  t_i5[IN_W+3-1 : IN_W+3 -OUT_W];
98  assign OUT_I6 =  t_i6[IN_W+3-1 : IN_W+3 -OUT_W];
99  assign OUT_I7 =  t_i7[IN_W+3-1 : IN_W+3 -OUT_W];
100 assign OUT_Q0 =  t_q0[IN_W+3-1 : IN_W+3 -OUT_W];
101 assign OUT_Q1 =  t_q1[IN_W+3-1 : IN_W+3 -OUT_W];
102 assign OUT_Q2 =  t_q2[IN_W+3-1 : IN_W+3 -OUT_W];
103 assign OUT_Q3 =  t_q3[IN_W+3-1 : IN_W+3 -OUT_W];
104 assign OUT_Q4 =  t_q4[IN_W+3-1 : IN_W+3 -OUT_W];
105 assign OUT_Q5 =  t_q5[IN_W+3-1 : IN_W+3 -OUT_W];
106 assign OUT_Q6 =  t_q6[IN_W+3-1 : IN_W+3 -OUT_W];
107 assign OUT_Q7 =  t_q7[IN_W+3-1 : IN_W+3 -OUT_W];
108 
109 endmodule
