49 module filter_serial(
50   input   clk, 
51   input   clk_enable, 
52   input   syn_rst, 
53   input   signed [15:0] filter_in, //sfix16_En15
54   output  signed [15:0] filter_out );//sfix16_En15
62 parameter signed [15:0] coeff1 = 16'b1110111010111001; //sfix16_En16
63 parameter signed [15:0] coeff2 = 16'b0100100010111111; //sfix16_En16
64 parameter signed [15:0] coeff3 = 16'b0111000110111010; //sfix16_En16
65 parameter signed [15:0] coeff4 = 16'b0111000110111010; //sfix16_En16
66 parameter signed [15:0] coeff5 = 16'b0100100010111111; //sfix16_En16
67 parameter signed [15:0] coeff6 = 16'b1110111010111001; //sfix16_En16
69 // Signals，用于选择当前是输出滤波器结果还是锁存输入，还是进行中间计算
70 reg  [2:0] cur_count;
72 always @ ( posedge clk)
73   if (syn_rst == 1'b1)
74     cur_count <= 3'b101;
75   else if (clk_enable == 1'b1) begin
76     if (cur_count == 3'b101)
77       cur_count <= 3'b000;
78     else 
79       cur_count <= cur_count + 1;
80   end
81 //控制信号，用于指示是否输出或者是否开始第一次乘加
82 wire FIRST_SUM_STAGE= (cur_count == 3'b101 &&clk_enable == 1'b1)? 1: 0;
84 wire OUTPUT_STAGE = (cur_count == 3'b000 && clk_enable == 1'b1)? 1 : 0;
86 //用于存储FIR的中间数据
87 reg  signed [15:0] delay_pipeline [0:5] ; // sfix16_En15
88 always @( posedge clk)
89   if (syn_rst == 1'b1) begin
90     delay_pipeline[0] <= 0;
91     delay_pipeline[1] <= 0;
92     delay_pipeline[2] <= 0;
93     delay_pipeline[3] <= 0;
94     delay_pipeline[4] <= 0;
95     delay_pipeline[5] <= 0;
96   end
97   else if (FIRST_SUM_STAGE == 1'b1) begin
98     delay_pipeline[0] <= filter_in;
99     delay_pipeline[1] <= delay_pipeline[0];
100     delay_pipeline[2] <= delay_pipeline[1];
101     delay_pipeline[3] <= delay_pipeline[2];
102     delay_pipeline[4] <= delay_pipeline[3];
103     delay_pipeline[5] <= delay_pipeline[4];
104   end
105 //用于选择哪一个存储数据进行乘法运算
106 wire[15:0] inputmux_1= (cur_count == 3'b000) ? delay_pipeline[0]:
107                    (cur_count == 3'b001) ? delay_pipeline[1]:
108                    (cur_count == 3'b010) ? delay_pipeline[2]:
109                    (cur_count == 3'b011) ? delay_pipeline[3]:
110                    (cur_count == 3'b100) ? delay_pipeline[4]:
111                    delay_pipeline[5];
112 wire[15:0] product_1_mux= (cur_count == 3'b000) ? coeff1:
113                    (cur_count == 3'b001) ? coeff2:
114                    (cur_count == 3'b010) ? coeff3:
115                    (cur_count == 3'b011) ? coeff4:
116                    (cur_count == 3'b100) ? coeff5:
117                    coeff6;
118 wire[31:0] mul_temp = inputmux_1 * product_1_mux;
119 //累加器中的输入输出与中间累加结果
120 wire signed [32:0] acc_sum_1; // sfix33_En31
121 wire signed [32:0] acc_in_1; // sfix33_En31
122 reg  signed [32:0] acc_out_1; // sfix33_En31
124 assign acc_sum_1={mul_temp[31],mul_temp} + acc_out_1;
125 assign acc_in_1=(OUTPUT_STAGE==1'b1)?{mul_temp[31],mul_temp}:acc_sum_1;
126                   
127 always @ ( posedge clk)
128   if(syn_rst == 1'b1)
129     acc_out_1 <= 0;   
130   else if (clk_enable == 1'b1)
131     acc_out_1 <= acc_in_1;  
132 
133 reg  signed [32:0] acc_final; // sfix33_En31
134 always @ ( posedge clk)
135   if (syn_rst == 1'b1)
136     acc_final <= 0;
137   else if (OUTPUT_STAGE == 1'b1)
138     acc_final <= acc_out_1;
139//对滤波器输出四舍五入
140 assign filter_out=(acc_final[31:0]+{acc_final[16],{15{~acc_final[16]}}})>>>16;
143 endmodule  // filter_serial
