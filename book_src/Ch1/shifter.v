module Shifter#(parameter N=8)(
input clk,
input reset, 
input left_in, 
input right_in,
input [1:0] mod, 
input [N-1:0] shift_in, 
output reg[N-1:0] shift_out
);
always @(posedge clk or posedge reset)
	if(reset)
		shift_out <= 'b0; //�����λ�Ĵ����ڲ�״̬
	else case(mod)
		2'b00:shift_out<={shift_out[N-2:0], right_in};//����
		2'b01:shift_out<={left_in, shift_out[N-1:1]}; //����
		2'b10:shift_out<= shift_in;				// ��������
	endcase
endmodule
