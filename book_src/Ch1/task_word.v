task�Ķ��壺                
task<������>;              // <=  task task_id;           
  <�˿ڼ����������������> // <=    [declaration]       
  <���1>                  // <=    procedural_statement
  <���2>                  // <=    procedural_statement
   .....                   // <=
  <���n>                  // <=    procedural_statement
endtask                    // <=  endtask 
                             
task �ĵ��ü������Ĵ���
<������>(�˿�1,�˿�2,...,�˿�n);

task��������������task��������task�ֿ����������task������������task��û�����Ƶģ�ֻ�е����е�task�����֮�󣬿��Ʋ��ܷ��ء��������û�л����ж������������͵ı�����

task find_max;      //������ṹ��ͷ������Ϊ find_max
 input  [15:0] x,y; //����˿�˵��
 output [15:0] tmp; //����˿�˵��

 if(x>y)            //������������������
   tmp = x;
 else
   tmp = y;

endtask 

�ڵ�һ�С�task������в����г��˿����ơ�
��������롢����˿ں�˫��˿������������ƣ���������û�����롢����Լ�˫��˿ڡ�
�����������������У�����ʹ�ó��ֲ����ۺϲ���������䣨ʹ����ΪƵ���ľ����ӳٿ�����䣬����#10ns��������������ɸ����񲻿��ۺϡ�
�������п��Ե������������������Ҳ���Ե���������
��������ṹ�ڲ��ܳ��� initial�� always���̿顣
���������п��Գ��֡�disable ��ֹ��䡱 �����ж�����ִ�е����񣬵����ǲ����ۺϵġ��������жϺ󣬳������̽����ص���������ĵط���������ִ�С�

�ڵ�������ʱ����Ҫע�����¼��㣺
����������ֻ�ܳ����ڹ��̿��ڡ�
�����������һ����ͨ����Ϊ�������Ĵ�������һ�¡�
�����������롢�����˫��˿�ʱ�������������������˿����б������źŶ˿�˳������ͱ����������ṹ�е�˳�������һ�¡���Ҫ˵�����ǣ����������˿ڱ���ͼĴ������͵����ݱ�����Ӧ��
���ۺ�����ֻ��ʵ������߼���Ҳ����˵���ÿ��ۺ������ʱ��Ϊ��0�� �������������������п��Դ���ʱ����ƣ���ʱ�ӣ����������������ĵ���ʱ�䲻Ϊ��0�� ��