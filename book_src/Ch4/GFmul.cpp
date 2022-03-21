#include<iostream>
#include<fstream>

using namespace std;
unsigned char GFmul(unsigned char a, unsigned char b)
{
  //GF(2^8) �˷�������������λ���ʵ��
  unsigned char result = 0;
  if((b&1) == 1) result = a;
  
  b >>= 1;
  for(int i = 1; i < 8; i ++) {
    if(a > 127) {
      a = (a << 1) ^ 0x1d;//x^8���л��򷽷���ǰ��������
    } else {
      a <<= 1;
    }
    if((b&1) == 1) result ^= a;
    
    b >>= 1;
  }
  return result;
}
int SerachGenerator(int result[])
{//�ҳ�����GF(2^8)������Ԫ
  unsigned char x = 2; //��2��ʼ����
  int len = 0;
  do {
    int count[256], i;
    for(i = 0; i < 256; i ++) count[i] = 0;

    count[x] ++;
    unsigned char tmp = x;
    for(i = 2; i < 256; i ++) {
      tmp = GFmul(tmp, x);//����GF��Ԫ�أ��൱��x��n����
      count[tmp] ++;//���ݴν����λ��״̬�ı䣬��Ϊ0��ʾ����ͨ��xȡ������
    }
    for(i = 1; i < 256; i ++) {//�����������Ƿ񶼿������ɣ�������xΪ����Ԫ
      if(count[i] != 1) break;
    }
    if(i == 256) result[len ++] = x;

    x ++; //����Ѱ����һ������Ԫ
  } while(x != 0);
  return len;
}
int main()
{//������е�����Ԫ��
  int result[256];
  int len = SerachGenerator(result);
  ofstream write("PrimeGenerator.txt");
  for(int i = 0; i < len; i ++) {
    write<<result[i]<<endl;
  }
  write.close();
  return 0;
}

