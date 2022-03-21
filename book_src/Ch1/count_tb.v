`timescale 1ns/1ns
module count_tb;
localparam DELY=100;
reg clk,reset;  //测试输入信号,定义为reg 型
wire[3:0] cnt;  //测试输出信号,定义为wire型

always#(DELY/2) clk = ~clk; //产生时钟波形     
initial
begin                 //激励信号定义
  clk =0; reset=0;
  #DELY   reset=1;
  #DELY   reset=0;
  #(DELY*100) $finish(2);
end
//定义结果显示格式
initial $monitor($time," clk=%d reset=%d cnt=%d",clk, reset,cnt);

//调用测试对象
count#(.N(4))U_cnt(
 .clk   (clk  )
,.clear (reset)
,.cnt_Q (cnt  )
);    

endmodule