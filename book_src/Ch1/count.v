module count#(parameter N=8)(
input clk,
input clear,
output[N-1:0] cnt_Q
);
reg[N-1:0] cnt;
assign cnt_Q = cnt;

always@(posedge clk)
  if(clear)
    cnt <= 'h0;      //ͬ���� 0���ߵ�ƽ��Ч
  else
    cnt <= cnt+1'b1; //��������

endmodule
