58 module fir_DA_simple_opt1 #(parameter N_taps=24,parameter BIT_WIDTH=16)(
60   input   clk, 
61   input   clk_enable, 
62   input   syn_rst, 
63   input   signed [BIT_WIDTH-1:0] filter_in, //sfix8_En7
64   output reg signed [BIT_WIDTH-1:0] filter_out); //sfix8_En7
65 
66 localparam DA_WIDTH =BIT_WIDTH+`log2(N_taps);
67 localparam SUM_WIDTH=BIT_WIDTH+`log2(BIT_WIDTH)+`log2(N_taps);
69 reg  signed [N_taps   -1:0] delay_pipeline[BIT_WIDTH-1:0];
78 wire signed [SUM_WIDTH-1:0] sum[BIT_WIDTH:0];
80 assign sum[0]=0;
81 integer j;
82 generate
83   genvar i,k;
84   for(i=0;i<BIT_WIDTH;i=i+1) begin : BIT_WIDTH_1bit_LUT
85       always @( posedge clk)
86       if (syn_rst == 1'b1) begin
87         for(j=0;j<N_taps;j=j+1) begin : bit_matrix_intial
88           delay_pipeline[i][j] <= 1'b0;
89         end
90       end else if (clk_enable == 1'b1) begin
91         delay_pipeline[i][0] <= filter_in[i];
92         for(j=1;j<N_taps;j=j+1) begin : bit_matrix
93           delay_pipeline[i][j] <= delay_pipeline[i][j-1];
94         end
95       end
96    //关键性代码，用于每4bit进行一次查表，如果改为6输入LUT，只需要在这替换4为6即可。
97     wire signed [DA_WIDTH -1:0] DA_data[N_taps/4-1:0];
98     for(k=0;k<N_taps/4;k=k+1) begin : rom_k
99       DA_bit_ROM #(DA_WIDTH,k)U_bit0(.addr(delay_pipeline[i][k*4+3:
100                    k*4]),.data(DA_data[k]));
101     end
102      //关键性代码，将4-LUT的结果进行累加，得到1bit的N_taps计算结果
103     reg signed [DA_WIDTH -1:0] DA_data_sum[N_taps/4:0];
104     always @(*)begin
105       DA_data_sum[0]=DA_data[0];
106       for(j=1;j<N_taps/4;j=j+1)
107         DA_data_sum[j]=DA_data_sum[j-1]+DA_data[j];
108     end
109     //关键性代码，将0~B-1比特进行累加，此处为描述方便，没有考虑有符号位的特殊处理
110     assign sum[i+1]=sum[i]+(DA_data_sum[N_taps/4]<<<i);
111   end
112 endgenerate
113 
114 always @ ( posedge clk)
115   if (syn_rst == 1'b1)
116     filter_out <= 0;
117   else if (clk_enable == 1'b1)//输出滤波结果，此处没有考虑动态调整输出幅度
118     filter_out <= sum[N_taps][SUM_WIDTH-1:SUM_WIDTH-BIT_WIDTH];
119 
120 endmodule
121 // 4bit ROM，为方便描述，需要对DA ROM数据归并到一起，并用generate语句统一处理。
122 module DA_bit_ROM #(parameter ROM_WDITH=18,parameter bit_no=0)(
123   input [3:0]addr,
124   output reg [ROM_WDITH-1:0] data
125 );
126   generate
127    if(bit_no==0) //选择哪一个ROM
128       always @(addr)
129       begin
130         case(addr)
131           4'b0000 : data = 18'b000000000000000000;
132           4'b0001 : data = 18'b000011000010100000;
146           4'b1111 : data = 18'b010110110010110000;
147           default : data = 18'b011001110101010000;
148         endcase
149       end
150     else if(bit_no==2)
151       always @(addr) // Rom 2
152       begin
153         case(addr) 
154           4'b0000 : data = 18'b000000000000000000;
170           default : data = 18'b011001110101010000;
171         endcase
172       end
174   endgenerate     
175 endmodule
