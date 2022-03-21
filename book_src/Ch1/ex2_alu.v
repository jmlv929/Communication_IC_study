module alu #(parameter N=8)(
  input     [  2:0] opcode, //������
  input     [N-1:0] a,      //������      
  input     [N-1:0] b,      //������ 
  output reg[N-1:0] out    //�������
);
localparam add  =3'd0;
localparam minus=3'd1;
localparam band =3'd2;
localparam bor  =3'd3;
localparam bnot =3'd4; 

always@(opcode or a or b)//��ƽ���е� always ��
	case(opcode)
		add:    out = a+b; //�Ӳ���
		minus:  out = a-b; //������
		band:   out = a&b; //����
		bor:    out = a|b; //���
		bnot:   out =~a;   //��
		default:out =8'hx; //δ�յ�ָ��ʱ���������̬
	endcase

endmodule
