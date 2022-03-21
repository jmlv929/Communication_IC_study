 1 module  b8tob10_enc8b10b (
 2 input clk,
 3 input reset_n,
 4 input idle_ins, // 当前周期是否为空闲
 5 input kin, //是否是控制信息
 6 input ena, // 使能信号
 7 input[7:0] datain, //输入1Byte 数据
 8 output reg kerr, //编码错误
 9 output reg [9:0] dataout, //输出数据
10 output reg valid,
11 input rdin, // 上一字节的RD
12 input rdforce, // 是否强迫使用默认RD
13 output reg rdout, // 本次RD计算的结果
14 output reg rdcascade );
15 reg  _Fkerr;
16 reg  [9:0] _Fdataout  ;
17 reg   _Fvalid  ;
18 wire  rdin  ;
19 wire  rdforce  ;
20 reg  _Frdout  ;
21 reg  _Srdcascade  ;
22 reg  [7:0] datain_d1, _Fdatain_d1  ;
23 reg  kin_d1, _Fkin_d1  ;
24 reg  kin_d2, _Fkin_d2  ;
25 reg  valid_pre1, _Fvalid_pre1  ;
26 reg  valid_pre2, _Fvalid_pre2  ;
27 wire  rd  ;
28 wire  [15:0] dlut_dat  ;
29 reg  [9:0] klut_dat, _Fklut_dat  ;
30 reg  kchar, _Skchar  ;
31 reg  [1:0] invert, _Sinvert  ;
32 reg  neutral, _Sneutral  ;
33 reg  [9:0] dat10b, _Sdat10b  ;
34 reg  [9:0] dat10b_pos, _Sdat10b_pos  ;
35 reg  speciald  ;
36 reg _Sspeciald;
37 b8tob10_encoding_lut  encoding_lut(.reset_n(reset_n), .clk(clk),.rdaddress_a(datain_d1), .q_a(dlut_dat)); //通过查找表实现编码，该函数请参见附加文档
38 assign rd = rdforce ? rdin:rdout;
39 
40 always @( * )  begin
41 // initialize flip-flop and combinational regs
42   _Fkerr = kerr;
43   _Fdataout = dataout;
44   _Fvalid = valid;
45   _Frdout = rdout;
46   _Srdcascade = 0;
47   _Fdatain_d1 = datain_d1;
48   _Fkin_d1 = kin_d1;
49   _Fkin_d2 = kin_d2;
50   _Fvalid_pre1 = valid_pre1;
51   _Fvalid_pre2 = valid_pre2;
52   _Fklut_dat = klut_dat;
53   _Skchar = 0;
54   _Sinvert = 0;
55   _Sneutral = 0;
56   _Sdat10b = 0;
57   _Sdat10b_pos = 0;
58   _Sspeciald = 0;
60 // mainline code
61   begin // *** put code block here ***
62   // --------------------- Channel ----------------------------
63   // Added for pipelining
64     begin 
65       _Fdatain_d1 = ena ? datain:8'b101_11100;
66       _Fkin_d1 = (kin | ~ ena);
67       _Fkin_d2 = kin_d1;
68       _Fvalid_pre2 = ena | idle_ins;
69       _Fvalid_pre1 = valid_pre2;
70       _Fvalid = valid_pre1;
71       case (datain_d1) //对控制字直接查表方式输出
72         8'b000_11100: _Fklut_dat = 10'b0010_111100;// K28.0
73         8'b001_11100: _Fklut_dat = 10'b1001_111100;// K28.1
74         8'b010_11100: _Fklut_dat = 10'b1010_111100;// K28.2
75         8'b011_11100: _Fklut_dat = 10'b1100_111100;// K28.3
76         8'b100_11100: _Fklut_dat = 10'b0100_111100;// K28.4
77         8'b101_11100: _Fklut_dat = 10'b0101_111100;// K28.5
78         8'b110_11100: _Fklut_dat = 10'b0110_111100;// K28.6
79         8'b111_11100: _Fklut_dat = 10'b0001_111100;// K28.7
80         8'b111_10111: _Fklut_dat = 10'b0001_010111;// K23.7
81         8'b111_11011: _Fklut_dat = 10'b0001_011011;// K27.7 
82         8'b111_11101: _Fklut_dat = 10'b0001_011101;// K29.7
83         8'b111_11110: _Fklut_dat = 10'b0001_011110;// K30.7
84         8'b111_11111: _Fklut_dat = 10'b1000_111100;// 10B_ERR
85         default:    _Fklut_dat = 10'b0101_111100;// K28.5
86       endcase
87 // case(datain_d1)
88       _Fkerr = kin_d2 & ~ dlut_dat[15];
89       if (kin_d2) begin 
90         _Sspeciald = 1'b0;
91         _Sinvert = 2'b11;//klut_dat[12:11];
92         _Sneutral = dlut_dat[14];
93         _Sdat10b = klut_dat[9:0];
94       end 
95       else
96       begin 
97         _Sspeciald = dlut_dat[13];
98         _Sinvert = dlut_dat[12:11];
99         _Sneutral = dlut_dat[10];
100         _Sdat10b = dlut_dat[9:0];
101       end // Data to use when current rd is positive.
102       // Invert certain bits based on lookup code
103       case (invert)
104         2'b00: _Sdat10b_pos = {dat10b[9], (dat10b[8] ^ speciald), (dat10b[7] ^ speciald), dat10b[6], dat10b[5:0]};
105         2'b01: _Sdat10b_pos = {dat10b[9:6], ~ dat10b[5:0]};
106         2'b10: _Sdat10b_pos = {~ dat10b[9:6], dat10b[5:0]};
107         2'b11: _Sdat10b_pos = {~ dat10b[9:6], ~ dat10b[5:0]};
108       endcase
109 // Choose between positive and negative disparity based on rd
110       if (rd) begin // disparity going from positive to (positive or negative)
111         _Fdataout = dat10b_pos;
112       end 
113       else
114       begin // disparity going from negative to (negative or positive)
115         _Fdataout = dat10b;
116       end // Calculate new running disparity
117       _Srdcascade = neutral ^ ~ rd;// For use in cascaded encoders
118       if (valid_pre1) begin 
119         _Frdout = rdcascade;
120       end // *** end of code block ***
121     end 
122   end // sequential_blocks
124 // update regs for combinational signals
125 // The non-blocking assignment causes the always block to 
126 // re-stimulate if the signal has changed
127   rdcascade <= _Srdcascade;
128   kchar <= _Skchar;
129   invert <= _Sinvert;
130   neutral <= _Sneutral;
131   dat10b <= _Sdat10b;
132   dat10b_pos <= _Sdat10b_pos;
133   speciald <= _Sspeciald;
134 end
135 always @(posedge clk or negedge reset_n) begin
136   if (!reset_n) begin
137     kerr<=0;
138     dataout<=0;
139     valid<=0;
140     rdout<=0;
141     datain_d1<=0;
142     kin_d1<=0;
143     kin_d2<=0;
144     valid_pre1<=0;
145     valid_pre2<=0;
146     klut_dat<=0;
147   end else begin
148     kerr<=_Fkerr;
149     dataout<=_Fdataout;
150     valid<=_Fvalid;
151     rdout<=_Frdout;
152     datain_d1<=_Fdatain_d1;
153     kin_d1<=_Fkin_d1;
154     kin_d2<=_Fkin_d2;
155     valid_pre1<=_Fvalid_pre1;
156     valid_pre2<=_Fvalid_pre2;
157     klut_dat<=_Fklut_dat;
158   end
159 end
160 endmodule
