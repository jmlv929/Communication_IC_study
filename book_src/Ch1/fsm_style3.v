module FSM_style3(
input clk,
input rst_n,
input in1,
input in2,
input in3,
output reg out1,
output reg out2,
output reg out3
);
reg[3:0] state,next_state;
parameter state0 = 4'b0001, state1 = 4'b0010,
          state2 = 4'b0100, state3 = 4'b1000;
//第一段 组合电路用于状态译码
always @(state or in1 or in2 or in3) 
  case(state)
    state0:if(in1) //根据条件，选择目标跳转状态
        next_state<=state1;
      else
        next_state <= state0;
    state1: next_state<=state2;
    state2: if(in2)
        next_state<=state3;
      else
        next_state <= state0;
    state3: if(in3)
        next_state<=state0;
      else
        next_state <= state3;
    default:
      next_state <= state0;
  endcase

//第二段：更新状态寄存器
always @(posedge clk or posedge rst_n)
  if(!rst_n)
    state <= state0;
  else
    state <= next_state;
//第三段：利用状态寄存器输出控制结果
always @(state)
begin
  //首先产生默认值，后续再改写，防止锁存器产生
  {out1,out2,out3}=3'b000;
  case(state)
    state1: {out1,out2,out3}=3'b100;
    state2: {out1,out2,out3}=3'b110;
    state3: {out1,out2,out3}=3'b111;
  endcase
end
endmodule
