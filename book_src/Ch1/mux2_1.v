module MUX2_1(
input a,b,sel,  //����a,b,selΪ����˿�
output out      //����outΪ����˿�
);
  wire a1, b1, sel_n;  //�����ڲ��ڵ��źţ����ߣ�
  not u1 (sel_n,sel ); //�������á��ǡ���Ԫ�� 
  and u2 (a1,a,sel_n); //�������á��롱��Ԫ�� 
  and u3 (b1,b,sel  ); //�������á��롱��Ԫ�� 
  or u4  (out,a1,b1 ); //�������á�����Ԫ�� 
endmodule
