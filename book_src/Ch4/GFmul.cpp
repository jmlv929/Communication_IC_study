#include<iostream>
#include<fstream>

using namespace std;
unsigned char GFmul(unsigned char a, unsigned char b)
{
  //GF(2^8) 乘法，采用逐项移位相加实现
  unsigned char result = 0;
  if((b&1) == 1) result = a;
  
  b >>= 1;
  for(int i = 1; i < 8; i ++) {
    if(a > 127) {
      a = (a << 1) ^ 0x1d;//x^8进行化简方法，前文已论述
    } else {
      a <<= 1;
    }
    if((b&1) == 1) result ^= a;
    
    b >>= 1;
  }
  return result;
}
int SerachGenerator(int result[])
{//找出所有GF(2^8)的生成元
  unsigned char x = 2; //从2开始查找
  int len = 0;
  do {
    int count[256], i;
    for(i = 0; i < 256; i ++) count[i] = 0;

    count[x] ++;
    unsigned char tmp = x;
    for(i = 2; i < 256; i ++) {
      tmp = GFmul(tmp, x);//生成GF域元素，相当于x的n次幂
      count[tmp] ++;//将幂次结果的位置状态改变，不为0表示可以通过x取幂生成
    }
    for(i = 1; i < 256; i ++) {//遍历所有数是否都可以生成，若是则x为生成元
      if(count[i] != 1) break;
    }
    if(i == 256) result[len ++] = x;

    x ++; //继续寻找下一个生成元
  } while(x != 0);
  return len;
}
int main()
{//输出所有的生成元。
  int result[256];
  int len = SerachGenerator(result);
  ofstream write("PrimeGenerator.txt");
  for(int i = 0; i < len; i ++) {
    write<<result[i]<<endl;
  }
  write.close();
  return 0;
}

