module MAC #(parameter N=8)(
	input clk,
	input reset,
	input [N-1:0]       opa,
	input [N-1:0]       opb,
	output reg[2*N-1:0] out
);

function[2*N-1:0] mult;//�������壬mult ������ɳ˷�����
	input[N-1:0] opa;    //����ֻ�ܶ��������
	input[N-1:0] opb;    //����˿�Ϊ����������
	reg[2*N-1:0] result; 
	integer i;
begin
	result = opa[0]? opb : 0;
	for(i= 1; i <= N; i = i+1)
	begin
		if(opa[i]==1) result=result+(opb<<(i-1));
	end
	mult=result;
end
endfunction

wire[2*N-1:0] sum;
assign sum = mult(opa,opb) + out;
always@(posedge clk or negedge reset)
if(!reset) 
	out<=0;
else    
	out<=sum;

endmodule
