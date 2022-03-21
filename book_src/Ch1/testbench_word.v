01 `timescale 1ns/1ns
02 module count_tb;
03 localparam DELY=100;
04 reg clk,reset;  //测试输入信号,定义为reg 型
05 wire[3:0] cnt;  //测试输出信号,定义为wire型
06 
07 always#(DELY/2) clk = ~clk; //产生时钟波形     
08 initial
09 begin                 //激励信号定义
10   clk =0; reset=0;
11   #DELY   reset=1;
12   #DELY   reset=0;
13   #(DELY*100) $finish(2);
14 end
15 //定义结果显示格式
16 initial $monitor($time," clk=%d reset=%d cnt=%d",clk, reset,cnt);
17 //调用测试对象
18 count#(.N(4))U_cnt(
19  .clk   (clk  )
20 ,.clear (reset)
21 ,.cnt_Q (cnt  )
22 );    
23 
24 endmodule
25 


assign [wire型变量名] =  赋值表达式 ；

module  连续赋值模块名 (
// I/O端口列表说明
input  输入端口列表
output  输出端口列表
);
// 数据类型说明
wire  结果信号名；
// 逻辑功能定义
assign <结果信号名> =逻辑表达式 ；
…
assign <结果信号名n>=逻辑表达式n；
endmodule

module  行为描述模块名 (
// I/O端口列表说明
input  输入端口列表
output reg 输出端口列表
);
// 数据类型说明
reg 中间变量 
// 逻辑功能定义
always @(敏感事件列表) //行为描述1 

begin
  if-else、case、for等行为语句
end
.........
always @(敏感事件列表) //行为描述n
begin
  if-else、case、for等行为语句
end
endmodule


always @ ( <敏感事件列表> )
begin
// for ,if-else, case, casex, casez 等行为语句
end

always@ ( a ) //当信号a的值发生改变时
always@ (a or b) //当信号a或信号b的值发生改变时

always@ ( posedge clock )  //当clock的上升沿到来时
always@ ( negedge clock )  //当clock的下降沿到来时
always@ ( posedge clock  or  negedge reset)
//当clock的上升沿到来或当reset的下降沿到来时

initial 
begin 
  语句1; 
  语句2; 
...... 
  语句n; 
end 

parameter clk_period = 20;
reg clk=0; // 直接设定初始值 
initial begin
  clk = 0; // 再次设定初始值，这个与reg定义初始化都有效
  forever #(clk_period/2) clk = ~clk;
end

