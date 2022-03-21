module alu #(parameter N=8)(
  input     [  2:0] opcode, //操作码
  input     [N-1:0] a,      //操作数      
  input     [N-1:0] b,      //操作数 
  output reg[N-1:0] out    //操作结果
);
localparam add  =3'd0;
localparam minus=3'd1;
localparam band =3'd2;
localparam bor  =3'd3;
localparam bnot =3'd4; 

always@(opcode or a or b)//电平敏感的 always 块
	case(opcode)
		add:    out = a+b; //加操作
		minus:  out = a-b; //减操作
		band:   out = a&b; //求与
		bor:    out = a|b; //求或
		bnot:   out =~a;   //求反
		default:out =8'hx; //未收到指令时，输出任意态
	endcase

endmodule
