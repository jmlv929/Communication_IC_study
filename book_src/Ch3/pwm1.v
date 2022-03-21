module PWM #(parameter PWM_WIDTH=16)(
	input clk,
	input syn_rst,
	input [PWM_WIDTH-1:0] pwm_percent,
	output reg pwm_out
);
reg [PWM_WIDTH-1:0] pwm_cnt;  //PMW脉宽计数器，周期计数
reg [PWM_WIDTH-1:0] pwm_load_value;

wire cnt_clear=(pwm_cnt=={{PWM_WIDTH}{1'b1}}) ? 1'b1:1'b0;
wire load_pwm_value=(pwm_cnt=={{PWM_WIDTH}{1'b0}}) ? 1'b1:1'b0;
always @(posedge clk)
  if(syn_rst)
  	pwm_cnt<=0;
  else if(cnt_clear)
  	pwm_cnt<=0;
	else
  	pwm_cnt<=pwm_cnt+1;

always @(posedge clk)
	if(syn_rst)
		pwm_load_value<=0;
	else if(cnt_clear)
		pwm_load_value<=pwm_percent;
	
always @(posedge clk)
  if(syn_rst)
  	pwm_out<=1'b1;
  else if(pwm_cnt<pwm_load_value)
  	pwm_out<=1'b1;
  else
  	pwm_out<=1'b0;
  	
endmodule


