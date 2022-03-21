module adder_N#(parameter N=8)(
  input[N-1:0] ina,inb,
  input cin,
  output[N-1:0]sum,
  output cout
);
  assign{cout,sum}=ina+inb+cin;
endmodule
module compare_N#(parameter N=8)(
  input [N-1:0] a,b,  // �Ƚ�����
  output equal // �ȽϽ��
);
  assign equal =(a==b) ? 1 : 0;//�ȽϽ��
endmodule
module decoder3_8(
  input  [2:0] in,
  output [7:0] out
);
  assign out = 1'b1 << in; //���ݴ�in�������ֵ,�����λ��1���ƶ�Ӧλ��
endmodule
module decoder8_3 (
  input      [7:0]in ,// 8bit���룬����ת��Ϊ3bit�Ľ��ձ���
  output reg [2:0]out,// 3bit������������Ӧ3-8�����ϵ
  output reg none_on  // ��ʾ�Ƿ����룬����8'b1100_0000�����ǷǷ�����
);
always @( * )
       if(in[7]) {none_on,out[2:0]}=4'b0111; //ʹ��if_else���ʵ��������ֵ
  else if(in[6]) {none_on,out[2:0]}=4'b0110; //��9����֧�����������ĵ�3λ��8�ֱ��뷽ʽ
  else if(in[5]) {none_on,out[2:0]}=4'b0101;
  else if(in[4]) {none_on,out[2:0]}=4'b0100;
  else if(in[3]) {none_on,out[2:0]}=4'b0011;
  else if(in[2]) {none_on,out[2:0]}=4'b0010;
  else if(in[1]) {none_on,out[2:0]}=4'b0001;
  else if(in[0]) {none_on,out[2:0]}=4'b0000;
  else           {none_on,out[2:0]}=4'b1000;
endmodule
module mux_N#(parameter N=8)(
  input [N-1:0] a,b,
  input sel,
  output[N-1:0] out
);
  //ʹ��assign������selѡ��a,b
  assign out = sel ? a : b;  //��selΪ1ʱ��outΪa������Ϊb
endmodule
module mux_N1#(parameter N=6)(
  input [N-1:0] a,b,
  input sel,
  output reg[N-1:0] out
);
  always @( * )
    if(sel) //ʹ��if_else����������ź�sel��ֵ
      out=a;
    else
      out=b;
endmodule
module mux_N2#(parameter N=6)(
  input [N-1:0] a,b,
  input sel,
  output reg[N-1:0] out
);
  always @( * )
    case(sel) //ʹ��if_else����������ź�sel��ֵ
      1'b0:out=a;
      1'b0:out=b;
      default:out=a;
    endcase
 endmodule
// ��������ֵ��佨����̬��ģ��
module tri_Gate#(parameter N=6)(
  input [N-1:0] in,
  input         enable,
  output[N-1:0] out
); //ʹ��assign���������״̬
  assign out = enable? in: 'bz;
endmodule
// ͨ��ʵ������ԭ�primitive����ʵ����̬��ģ��
module tri_Gate1#(parameter N=6)(
  input [N-1:0] in,
  input         enable,
  output[N-1:0] out
); //bufif1��һ��Verilog�ż�ԭ��
generate
genvar i;
  for (i=0;i<N;i=i+1) begin:buf_test
    bufif1 mybuf1(out[i], in[i], enable);
  end
endgenerate
endmodule
// ��̬˫�����������ʵ����
module bidir #(parameter N=6)(
  input [N-1:0] in,
  input         enable,
  inout [N-1:0] tri_inout,
  output[N-1:0] out
);
  assign tri_inout = enable? in : 'bz;//��̬�ŵ�����Ϊin
  assign out = tri_inout;             //��̬�ŵ����
endmodule

module DFF_N #(parameter N=6)(
  input     CLK,
  input     RESET_N,
  input     [N-1:0]D,
  output reg[N-1:0]Q
);
always@(posedge CLK or negedge RESET_N)
  if(!RESET_N)
    Q<='h0;
  else
    Q <= D;
endmodule
// ����ת����λ�Ĵ������ʵ����
module shiftReg_N #(parameter N=8)(
  input CLK,RESET_N,
  input din,
  output reg[N-1:0] dout
);
always @(posedge CLK)
  if(!RESET_N) //����
    dout <= 'b0;
  else begin
    dout[N-1:1]<= dout[N-2:0]; //����һλ
    dout[0]<= din; //�������źŷ���Ĵ��������λ
  end
endmodule
// 16λ���������ʵ��һ��
module counter_N #(parameter N=16)(
  input  clk,
  input  load,
  input     [N-1:0]data,
  output reg[N-1:0]cnt,
  output cout // ����������־
);
always @(posedge clk)
  if( load )   //�����źż��
    cnt <= data;
  else
    cnt <= cnt + 1;
assign cout= & cnt;
endmodule
module counter_N2 #(parameter N=16)(
  input  clk,
  input  load,
  input     [N-1:0]data,
  output reg[N-1:0]cnt,
  output reg cout // ����������־
);
  reg [N-1:0]preout;// ����FSM����һ״̬����ʱΪ�������
  always @(posedge clk)
    cnt <= preout;
  always @( *) begin
    {cout, preout} = cnt + 1'b1;     //��λ����
    if(load) preout = data;     //�жϼ����ź�
  end
endmodule
// ��ƽ������������
module latch_N#(parameter N=16)(
  input clk,
  input  [N-1:0]d,
  output [N-1:0]q
);
  assign q = clk ? d : q; //ͨ��assign��䣬ʵ�ֵ���һ��������
endmodule
module latch_N1#(parameter N=16)(
  input clk,
  input     [N-1:0]d,
  output reg[N-1:0]q
);
  always @( * )
  if(clk) //clkΪ�ߵ�ƽʱ��q����dֵ
    q = d;
endmodule
//����ִ��ģ�� 2

// ����ˮ�߷�ʽ 8 λȫ����
module adderN #(parameter N=8)(
  input clk,cin,
  input      [N-1:0] ina,inb,
  output reg [N-1:0] sum,
  output reg         cout
);
reg[7:0] tempa,tempb;
reg tempc;
always @(posedge clk)begin
  tempa=ina;  tempb=inb;  tempc=cin;      //������������
end
always @(posedge clk) begin
  {cout,sum}=tempa+tempb+tempc;
end
endmodule
// 4 ����ˮ��ʽ�� 8 λȫ����
module pipeline_adderN #(parameter N=8)(
  input clk,cin,
  input      [N-1:0] ina,inb,
  output reg [N-1:0] sum,
  output reg         cout
);
reg[7:0] tempa,tempb;
reg      tempci,firstco,secondco,thirdco;
reg[1:0] firsts,thirda,thirdb;
reg[3:0] seconda,secondb,seconds;
reg[5:0] firsta,firstb,thirds;
always @(posedge clk)begin
  tempa=ina;  tempb=inb;  tempci=cin;    //�������ݻ���
end
always @(posedge clk) begin
  {firstco,firsts}=tempa[1:0]+tempb[1:0]+tempci; //��һ���ӣ��� 2 λ��
  firsta=tempa[7:2];        //δ�μӼ�������ݻ���
  firstb=tempb[7:2];
end
always @(posedge clk) begin
  //�ڶ����ӣ��� 2��3 λ��ӣ�
  {secondco,seconds}={firsta[1:0]+firstb[1:0]+firstco,firsts};
  seconda=firsta[5:2];        //���ݻ���
  secondb=firstb[5:2];
end
always @(posedge clk) begin   //�������ӣ��� 4��5 λ��ӣ�
  {thirdco,thirds}={seconda[1:0]+secondb[1:0]+secondco,seconds};
  thirda=seconda[3:2];    //���ݻ���
  thirdb=secondb[3:2];
end
always @(posedge clk) begin  //���ļ��ӣ�����λ��ӣ�
  {cout,sum}={thirda[1:0]+thirdb[1:0]+thirdco,thirds};
end
endmodule
module add_ahead #(parameter N=8)(
input         cin,
input [N-1:0] a,b,
output[N-1:0] sum,
output     cout
);
wire[N-1:0] G,P,C;
assign C[0]=cin;
assign cout=C[N-1];
generate
genvar i;
  for(i=0;i<N;i=i+1)begin : adder_ahead
    assign G[i]=a[i]&b[i];        //������iλ��λֵ
    assign P[i]=a[i]|b[i];
    assign sum[i]=G[i]^P[i]^C[i];
  end
  for(i=1;i<N;i=i+1)begin  : adder_carry
    assign C[i]=G[i-1]|(P[i-1]&C[i-1]);//������iλ��λֵ
  end
endgenerate
endmodule
module FSM(
  input clk,rst_n,start,step2,step3,
  output reg[2:0] out
);
reg[1:0] state,next_state;
localparam  state0=2'b00,state1=2'b01,state2=2'b11,state3=2'b10;
always@(posedge clk or negedge rst_n) //����FSM״̬
  if (!rst_n) state <= state0;
  else state <= next_state;
always@(*)  // FSM ��һ״̬���
case(state)
  state0: begin
    if(start) next_state <=state1;
    else      next_state <=state0;
  end
  state1: begin
    next_state <= state2;
  end
  state2: begin
    if(step2) next_state <=state3;
    else      next_state <=state0;
  end
  state3: begin
    if(step3) next_state <=state0;
    else      next_state <=state3;
  end
  default:    next_state <=state0;
endcase
always @(state)       //�ý��̶�������߼���FSM �������
case(state)
  state0: out=3'b001;
  state1: out=3'b010;
  state2: out=3'b100;
  state3: out=3'b111;
  default:out=3'b001;
endcase
endmodule
module trigger #(parameter wait_time=12,N=5) (
  input clk,
  input trig_in,
  output trig_flag
);
  reg [N-1:0] cnt;
  reg state=0; //
  assign trig_flag=(cnt=='b0)?1'b1:1'b0;
  always@(posedge clk)
    if(state==0)
      cnt<=wait_time;
    else if(state)
      cnt<=cnt-1;
  always@(posedge clk)
    if(trig_flag)
      state<=1'b0;
    else if(trig_in)
      state<=1'b1;
endmodule
module edge_detect(
  input  clk,
  input  rst_n,
  input  trig_in,
  output pos_edge,
  output neg_edge
); //
// 
  reg trig_in_r0,trig_in_r1,trig_in_r2;
  always@(posedge clk or negedge rst_n)
    if(!rst_n)begin
      trig_in_r0 <= 1'b0;
      trig_in_r1 <= 1'b0;
      trig_in_r2 <= 1'b0;
    end else begin
      trig_in_r0 <= trig_in;
      trig_in_r1 <= trig_in_r0;
      trig_in_r2 <= trig_in_r1;
    end
  assign pos_edge = trig_in_r1 & ~trig_in_r2;
  assign neg_edge = ~trig_in_r1 & trig_in_r2;

endmodule