module FSM(
input clk,
input reset,
input start,
input step2,
input step3,
output reg[2:0] fsm_out
);
localparam state0=2'b00;
localparam state1=2'b01;
localparam state2=2'b11;
localparam state3=2'b10;
//��׼����ʽ���룬ÿ�����ڸ��µ�ǰ״̬
reg[1:0] state;

reg[1:0] next_state;
always@(posedge clk or negedge reset)
 if(!reset)
   state <= state0;
 else
   state <= next_state;

//���ݵ�ǰ״̬�����룬ȷ����һ�����ڵ�״̬
always@(state or start or step2 or step3)
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
      next_state <=state0;
    else
      next_state <=state3;
    end
    default:  next_state <=state0;//ȱʡ״̬
  endcase
end

always @(state) //�ý��̶���FSM�����
  case(state)
    state0: fsm_out=3'b001;
    state1: fsm_out=3'b010;
    state2: fsm_out=3'b100;
    state3: fsm_out=3'b111;
    default:fsm_out=3'b001; // default��䣬�����������Ĳ���
  endcase

endmodule