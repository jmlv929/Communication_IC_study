module FSM_style1(
input clk,
input rst_n,
input in1,
input in2,
input in3,
output reg out1,
output reg out2,
output reg out3
);
reg[3:0] state;
parameter state0 = 4'b0001,state1 = 4'b0010,
          state2 = 4'b0100,state3 = 4'b1000;
always @(posedge clk or negedge rst_n)
  if(!rst_n)
    state <= state0;
  else
  case(state)
    state0: begin
      if(in1) begin
        state<=state1;
        out1 <= 1;
      end
      else state<=state0;
    end
    state1: begin
      state<=state2;
      out2 <= 1;
    end
    state2: begin
      if(in2) begin
        state<=state3; out3 <= 1;
      end
      else state<=state0;
    end
    state3: begin
      if(in3) state<=state0;
      else begin
        state<=state0;out3 <= 1;
      end
    end
    default:
    begin
      state <= state0; out1 =0;out2=0;out3=0;
    end
  endcase

endmodule
