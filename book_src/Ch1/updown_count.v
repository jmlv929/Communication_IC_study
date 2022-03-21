module updown_count#(parameter N=8)(
input clk,
input clear,
input load,
input up_down,
input [N-1:0] preset_D,
output[N-1:0] cnt_Q
);
reg[N-1:0] cnt;
assign cnt_Q = cnt;

always@(posedge clk)
  if(clear)
    cnt <= 'h0;      //ͬ���� 0���ߵ�ƽ��Ч
  else if(load)
    cnt <= preset_D; //ͬ��Ԥ��
  else if(up_down)
    cnt <= cnt+1;    //�ӷ�����
  else
    cnt <= cnt-1;    //��������

endmodule
