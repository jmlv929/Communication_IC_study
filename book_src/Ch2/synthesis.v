module adder_N#(parameter N=8)(
  input[N-1:0] ina,inb,
  input cin,
  output[N-1:0]sum,
  output cout
);
  assign{cout,sum}=ina+inb+cin;
endmodule
module compare_N#(parameter N=8)(
  input [N-1:0] a,b,  // 比较输入
  output equal // 比较结果
);
  assign equal =(a==b) ? 1 : 0;//比较结果
endmodule
module decoder3_8(
  input  [2:0] in,
  output [7:0] out
);
  assign out = 1'b1 << in; //根据从in口输入的值,把最低位的1左移对应位数
endmodule
module decoder8_3 (
  input      [7:0]in ,// 8bit输入，用于转换为3bit的紧凑编码
  output reg [2:0]out,// 3bit输出，与输入对应3-8编码关系
  output reg none_on  // 表示非法输入，例如8'b1100_0000，就是非法输入
);
always @( * )
       if(in[7]) {none_on,out[2:0]}=4'b0111; //使用if_else语句实现向量赋值
  else if(in[6]) {none_on,out[2:0]}=4'b0110; //共9个分支，其中向量的低3位有8种编码方式
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
  //使用assign语句根据sel选择a,b
  assign out = sel ? a : b;  //当sel为1时，out为a；否则为b
endmodule
module mux_N1#(parameter N=6)(
  input [N-1:0] a,b,
  input sel,
  output reg[N-1:0] out
);
  always @( * )
    if(sel) //使用if_else语句检查输入信号sel的值
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
    case(sel) //使用if_else语句检查输入信号sel的值
      1'b0:out=a;
      1'b0:out=b;
      default:out=a;
    endcase
 endmodule
// 用连续赋值语句建立三态门模型
module tri_Gate#(parameter N=6)(
  input [N-1:0] in,
  input         enable,
  output[N-1:0] out
); //使用assign语句决定输出状态
  assign out = enable? in: 'bz;
endmodule
// 通过实例化该原语（primitive），实现三态门模型
module tri_Gate1#(parameter N=6)(
  input [N-1:0] in,
  input         enable,
  output[N-1:0] out
); //bufif1是一个Verilog门级原语
generate
genvar i;
  for (i=0;i<N;i=i+1) begin:buf_test
    bufif1 mybuf1(out[i], in[i], enable);
  end
endgenerate
endmodule
// 三态双向驱动器设计实例。
module bidir #(parameter N=6)(
  input [N-1:0] in,
  input         enable,
  inout [N-1:0] tri_inout,
  output[N-1:0] out
);
  assign tri_inout = enable? in : 'bz;//三态门的输入为in
  assign out = tri_inout;             //三态门的输出
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
// 串并转化移位寄存器设计实例。
module shiftReg_N #(parameter N=8)(
  input CLK,RESET_N,
  input din,
  output reg[N-1:0] dout
);
always @(posedge CLK)
  if(!RESET_N) //清零
    dout <= 'b0;
  else begin
    dout[N-1:1]<= dout[N-2:0]; //左移一位
    dout[0]<= din; //把输入信号放入寄存器的最低位
  end
endmodule
// 16位计数器设计实例一。
module counter_N #(parameter N=16)(
  input  clk,
  input  load,
  input     [N-1:0]data,
  output reg[N-1:0]cnt,
  output cout // 计数器满标志
);
always @(posedge clk)
  if( load )   //加载信号检测
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
  output reg cout // 计数器满标志
);
  reg [N-1:0]preout;// 类似FSM的下一状态，此时为计数结果
  always @(posedge clk)
    cnt <= preout;
  always @( *) begin
    {cout, preout} = cnt + 1'b1;     //进位操作
    if(load) preout = data;     //判断加载信号
  end
endmodule
// 电平敏感型锁存器
module latch_N#(parameter N=16)(
  input clk,
  input  [N-1:0]d,
  output [N-1:0]q
);
  assign q = clk ? d : q; //通过assign语句，实现的是一个锁存器
endmodule
module latch_N1#(parameter N=16)(
  input clk,
  input     [N-1:0]d,
  output reg[N-1:0]q
);
  always @( * )
  if(clk) //clk为高电平时，q锁存d值
    q = d;
endmodule
//并行执行模块 2

// 非流水线方式 8 位全加器
module adderN #(parameter N=8)(
  input clk,cin,
  input      [N-1:0] ina,inb,
  output reg [N-1:0] sum,
  output reg         cout
);
reg[7:0] tempa,tempb;
reg tempc;
always @(posedge clk)begin
  tempa=ina;  tempb=inb;  tempc=cin;      //输入数据锁存
end
always @(posedge clk) begin
  {cout,sum}=tempa+tempb+tempc;
end
endmodule
// 4 级流水方式的 8 位全加器
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
  tempa=ina;  tempb=inb;  tempci=cin;    //输入数据缓存
end
always @(posedge clk) begin
  {firstco,firsts}=tempa[1:0]+tempb[1:0]+tempci; //第一级加（低 2 位）
  firsta=tempa[7:2];        //未参加计算的数据缓存
  firstb=tempb[7:2];
end
always @(posedge clk) begin
  //第二级加（第 2、3 位相加）
  {secondco,seconds}={firsta[1:0]+firstb[1:0]+firstco,firsts};
  seconda=firsta[5:2];        //数据缓存
  secondb=firstb[5:2];
end
always @(posedge clk) begin   //第三级加（第 4、5 位相加）
  {thirdco,thirds}={seconda[1:0]+secondb[1:0]+secondco,seconds};
  thirda=seconda[3:2];    //数据缓存
  thirdb=secondb[3:2];
end
always @(posedge clk) begin  //第四级加（高两位相加）
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
    assign G[i]=a[i]&b[i];        //产生第i位本位值
    assign P[i]=a[i]|b[i];
    assign sum[i]=G[i]^P[i]^C[i];
  end
  for(i=1;i<N;i=i+1)begin  : adder_carry
    assign C[i]=G[i-1]|(P[i-1]&C[i-1]);//产生第i位进位值
  end
endgenerate
endmodule
module FSM(
  input clk,rst_n,start,step2,step3,
  output reg[2:0] out
);
reg[1:0] state,next_state;
localparam  state0=2'b00,state1=2'b01,state2=2'b11,state3=2'b10;
always@(posedge clk or negedge rst_n) //更新FSM状态
  if (!rst_n) state <= state0;
  else state <= next_state;
always@(*)  // FSM 下一状态输出
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
always @(state)       //该进程定义组合逻辑（FSM 的输出）
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