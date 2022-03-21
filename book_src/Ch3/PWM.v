01 module PWM #(parameter PWM_WIDTH=16)(
02   input clk,
03   input syn_rst,
04   input [PWM_WIDTH-1:0] pwm_percent,
05   output reg pwm_out
06 );
07 reg [PWM_WIDTH-1:0] pwm_cnt; //PMW脉宽计数器，周期计数
08 reg [PWM_WIDTH-1:0] pwm_load_value; //下次PMW长度的内部采样锁存
09 
10 wire cnt_clear=(pwm_cnt=={{PWM_WIDTH}{1'b1}}) ? 1'b1:1'b0;
11 wire load_pwm_value=(pwm_cnt=={{PWM_WIDTH}{1'b0}}) ? 1'b1:1'b0;
12 always @(posedge clk)
13   if(syn_rst)
14     pwm_cnt<=0;
15   else if(cnt_clear)
16     pwm_cnt<=0;
17   else
18     pwm_cnt<=pwm_cnt+1; // PWM内部计数器
19
20 always @(posedge clk)
21   if(syn_rst)
22     pwm_load_value<=0;
23   else if(cnt_clear)
24     pwm_load_value<=pwm_percent; // 装载下次PWM的百分比
25   
26 always @(posedge clk)
27   if(syn_rst)
28     pwm_out<=1'b1;
29   else if(pwm_cnt<pwm_load_value) // 比较计数器输出占空比
30     pwm_out<=1'b1;
31   else
32     pwm_out<=1'b0;
33     
34 endmodule
