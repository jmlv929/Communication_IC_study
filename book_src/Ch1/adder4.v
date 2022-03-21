module  ADD_1b(
input a,b,cin,
output sum,cout
);
  assign {cout,sum} = a+b+cin;
endmodule
//����1bit�ӷ�����ADD_1b�����нṹ������
module adder_4bit(
input  [3:0] a,b,
input  cin,
output [3:0] sum,
output cout
);
wire cout0;  //��0λ�Ľ�λ�źţ�
wire cout1;  //��1λ�Ľ�λ�źţ�
wire cout2;  //��2λ�Ľ�λ�źţ�
//�����߼�����,����һλȫ������ģ�鹹����λȫ����
  ADD_1b addr0(.a(a[0]),.b(b[0]),.cin(cin  ),.sum(sum[0]),.cout(cout0));
  ADD_1b addr1(.a(a[1]),.b(b[1]),.cin(cout0),.sum(sum[1]),.cout(cout1));
  ADD_1b addr2(.a(a[2]),.b(b[2]),.cin(cout1),.sum(sum[2]),.cout(cout2));
  ADD_1b addr3(.a(a[3]),.b(b[3]),.cin(cout2),.sum(sum[3]),.cout(cout ));
endmodule
