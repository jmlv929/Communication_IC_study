module FSM(
input clk,
input reset,
input start,
input step2,
input step3,
input step4,
output reg[2:0] fsm_out
);
localparam fsm_width=3;
localparam state0=3'b000;
localparam state1=3'b001;
localparam state2=3'b011;
localparam state3=3'b010;
localparam state4=3'b100;
//标准三段式编码，每个周期更新当前状态
reg[fsm_width-1:0] state;
reg[fsm_width-1:0] next_state;
always@(posedge clk or negedge reset)
 if(!reset)
   state <= state0;
 else
   state <= next_state;

//根据当前状态和输入，确认下一个周期的状态
always@( * )
begin
  case(state)
    state0: begin
    if(start)
      next_state <=state1;
    else
      next_state <=state0;
    end
    state1: begin
      next_state <= state2;
    end
    state2: begin
    if(step2)
      next_state <=state3;
    else
      next_state <=state0;
    end
    state3: begin
    if(step3)
      next_state <=state4;
    else
      next_state <=state3;
    end

    state4: begin
    if(step4)
      next_state <=state0;
    else
      next_state <=state4;
    end

    default:  next_state <=state0;//缺省状态
  endcase
end

always @(state) //该进程定义FSM的输出
  case(state)
    state0: fsm_out=3'b001;
    state1: fsm_out=3'b010;
    state2: fsm_out=3'b100;
    state3: fsm_out=3'b111;
    default:fsm_out=3'b001; // default语句，避免锁存器的产生
  endcase

endmodule