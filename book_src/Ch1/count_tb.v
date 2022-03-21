`timescale 1ns/1ns
module count_tb;
localparam DELY=100;
reg clk,reset;  //���������ź�,����Ϊreg ��
wire[3:0] cnt;  //��������ź�,����Ϊwire��

always#(DELY/2) clk = ~clk; //����ʱ�Ӳ���     
initial
begin                 //�����źŶ���
  clk =0; reset=0;
  #DELY   reset=1;
  #DELY   reset=0;
  #(DELY*100) $finish(2);
end
//��������ʾ��ʽ
initial $monitor($time," clk=%d reset=%d cnt=%d",clk, reset,cnt);

//���ò��Զ���
count#(.N(4))U_cnt(
 .clk   (clk  )
,.clear (reset)
,.cnt_Q (cnt  )
);    

endmodule