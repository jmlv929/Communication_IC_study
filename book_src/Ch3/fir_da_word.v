58 module fir_da #(parameter N_taps=9,parameter BIT_WIDTH=16)(
59   input   clk, 
60   input   clk_enable, 
61   input   syn_rst, 
62   input   signed [BIT_WIDTH-1:0] filter_in, //sfix8_En7
63   output reg signed [BIT_WIDTH-1:0] filter_out); //sfix8_En7
65 localparam DA_WIDTH =BIT_WIDTH+`log2(N_taps);
66 localparam SUM_WIDTH=BIT_WIDTH+`log2(BIT_WIDTH)+`log2(N_taps);
67 
68 reg  signed [N_taps   -1:0] delay_pipeline[BIT_WIDTH-1:0];
69 wire signed [DA_WIDTH -1:0] DA_data[BIT_WIDTH-1:0];
70 wire signed [SUM_WIDTH-1:0] sum[BIT_WIDTH:0];
72 assign sum[0]=0;
73 integer j;
74 generate
75   genvar i; // 每个单独bit都生成一个always块
76   for(i=0;i<BIT_WIDTH;i=i+1) begin : BIT_WIDTH_1bit_LUT
77     always @( posedge clk) 
78       if (syn_rst == 1'b1) begin
79         for(j=0;j<N_taps;j=j+1) begin : bit_matrix_intial
80           delay_pipeline[i][j] <= 1'b0;
81         end
82       end else if (clk_enable == 1'b1) begin
83         delay_pipeline[i][0] <= filter_in[i];
84         for(j=1;j<N_taps;j=j+1) begin : bit_matrix  // 依次移位和缓存数据
85           delay_pipeline[i][j] <= delay_pipeline[i][j-1];
86         end
87       end
88     // 通过DA查表，得到每个bit的计算结果
89     DA_ROM #(N_taps,DA_WIDTH)U_bit(.addr(delay_pipeline[i]),.data(DA_data[i]));
91     assign sum[i+1]=sum[i]+(DA_data[i]<<<i); //对每bit结果进行移位累加，保证权重正确
92   end
93 endgenerate
94 
95 always @ ( posedge clk)
96   if (syn_rst == 1'b1)
97     filter_out <= 0;
98   else if (clk_enable == 1'b1) // 输出滤波器结果，没有做幅度调整。
99     filter_out <= sum[N_taps][SUM_WIDTH-1:SUM_WIDTH-BIT_WIDTH];
100 
101 endmodule
102  //给出N阶滤波器，N个bit组成的LUT表。所有bit位数都用相同的表
103 module DA_ROM #(parameter N_taps=5,parameter ROM_WDITH=18)(
104   input [N_taps-1:0]addr,
105   output reg [ROM_WDITH-1:0] data
106 );
107   always @(addr)
108   begin
109     case(addr)
110       5'b00000 : data = 18'b000000000000000000;
111       5'b00001 : data = 18'b000011000010100000;
141       5'b11111 : data = 18'b011001110101010000;
142       default : data = 18'b011001110101010000;
143     endcase
144   end
145 endmodule
