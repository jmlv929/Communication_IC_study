#include<iostream>
#include <cstdlib>
#include <ctime>
#include <string>
using namespace std;
/*
 *对于多项式的,我们可以用一个二进制数来表示进行减法
 *例如：x^3+x+1 可以以二进制数1011来表示,即十进制数的11
 *本题给定既约多项式 x^8+x^4+x^3+x+1 可以通过用二进制数100011011来表示
 *即十进制数283
 *因此其生成的有限域GF(2^8)/(x^8+x^4+x^3+x+1),共有2^8=256个元素
 */

//定义一些常量
const int M = 283;  //x^8+x^4+x^3+x+1
const int p = 2;   //模2
const int N = 256;  //有限域内的元素个数

int a,b;     //在有限域内选取的两个元素

int remainvalue;  //余数式
int x,y;

class GFpn
{
public:
    //在有限域内部随机选取两个元素
    void random_element();

    //返回一个十进制数的二进制数的最高位
    int index_of_binary_max(int value);

    //将一个十进制数转化为对应的多项式字符串
    string value_into_polynomial(int value);

    //求一个数的2次幂,即返回2^value.
    int power_of_value(int value);

    //返回多项式的除法,remainvalue为余数
    int divide(int a,int b,int &remainvalue); 

    //相当于ax - q * bx 在多项式异或的范畴下
    //三元组运算
    int Tx(int ax,int q,int bx);
    
    //扩展的欧几里得算法
    //其中x返回的是b mod m的多项式的乘法逆元
    //所对应的的十进制数表达式
    int extent_gcd(int m,int b,int &x,int &y);

    //定义多项式有限域内的加法运算
    //实际上是两个数的异或
    int polynomial_add(int a,int b);

    //定义多项式有限域内的减法运算
    //实际上也是两个数的异或
    int polynomial_sub(int a,int b);

    //定义多项式有限域内的乘法运算
    //通过移位,来实现逐位异或
    int polynomial_mul(int a,int b);

    //定义多项式的除法运算
    //实质上也是乘以多项式在有限域的逆元
    int polynomial_div(int a,int b);
};

//在有限域中随机选取两个元素
//等价为在0——N-1中随机选取两个数
void GFpn::random_element()
{
    a = rand() % N;
    b = rand() % N;
}


//求数的二进制数的最高位
int GFpn::index_of_binary_max(int value)
{
    int tmp = 1;
    int count = 0;
    int i;
    for(i = 0;i < sizeof(int) * 8;i++)
    {
          if(value & tmp)
             count = i;
          tmp = tmp * 2;
    }
    return count;
}

//将一个数转化为多项式
//如：11——>1011——>x^3+x+1
string GFpn::value_into_polynomial(int value)
{
    string result;
    int i;
    int tmp = 1;
    int flag = 0;
    int c = index_of_binary_max(value);
    for(i = 0;i < sizeof(int) * 8;i++)
    {
          if(value & tmp)
          {
             if(i == 0)
             {
                 result += "1";
             }
             else if(i == 1)
             {
               result += "x";
             }
             else
             {
               result += "x^";
               result += '0'+ i;
             }
             flag = 1;
             if(i < c)
               result += "+";
          }   
          tmp = tmp * 2;
    }
    if(flag == 0)
      result += "0";
    return  result;
}

//求一个数的2次幂,即返回2^value.
int GFpn::power_of_value(int value)
{
    return 1 << (value);
}


//返回多项式的除法,remainvalue为余数
int GFpn::divide(int a,int b,int &remainvalue)
{
    int aindex = index_of_binary_max(a);
    int bindex = index_of_binary_max(b);
    if(aindex < bindex)
    {
        remainvalue = a;
        return 0;
    }
    int c = aindex - bindex;
    int tmp = b;
    tmp = tmp << c;
    a = a ^ tmp;
    return power_of_value(c) | divide(a,b,remainvalue);
}


//相当于ax - q * bx 在多项式异或的范畴下
//三元组运算
int GFpn::Tx(int ax,int q,int bx)
{
    int tmp = 1;
    int value = 0;
    int i;
    for(i = 0;i < sizeof(int) * 8;i++)
    {
          if(q & tmp)
          {
             value = value ^ (bx << i);   
          }   
          tmp = tmp * 2;
    }
    return ax ^ value;
}


//扩展的欧几里得算法
int GFpn::extent_gcd(int m,int b,int &x,int &y)
{
    //先定义(a1,a2,a3)三元组
    int a1 = 1,a2 = 0,a3 = m;
    //再定义(b1,b2,b3)三元组
    int b1 = 0,b2 = 1,b3 = b;
    int remainvalue=0;
    while(1)
    {
        if(b3==0)
            return a3;
        if(b3==1)
            return b3;
        int q = divide(a3,b3,remainvalue);
        //分别定义(t1,t2,t3)三元组
        int t1 = Tx(a1,q,b1);     //q = a3 / b3;(多项式范畴下)
        int t2 = Tx(a2,q,b2);     //t1<——a1 - q * b1
        int t3 = remainvalue;     //t2<——a2 - q * b2
        //迭代过程  
        //(a1,a2,a3)<——(b1,b2,b3)
        a1 = b1;a2 = b2;a3 = b3;
        //(b1,b2,b3)<——(t1,t2,t3)
        b1 = t1;b2 = t2;b3 = t3;
        x = b2;
        y = b3; 
    }
}

//定义多项式有限域内的加法运算
//实际上是两个数的异或
int GFpn::polynomial_add(int a,int b)
{
    int result;
    result = a ^ b;
    return result;
}

//定义多项式有限域内的减法运算
//实际上也是两个数的异或
int GFpn::polynomial_sub(int a,int b)
{
    int result;
    result = a ^ b;
    return result;
}

//定义多项式有限域内的乘法运算
//通过移位,来实现逐位异或
int GFpn::polynomial_mul(int a,int b)
{
    int result = 0;
    int remain = 0;
    int num = index_of_binary_max(b);
    int i;
    for(i = 0;i < num;i++)
    {
        if(b & 1)
        {
            result ^= a;
        }
        a <<= 1;
        b >>= 1;
    }
    result ^= a;
    result = divide(result,M,remain);
    return remain;
}

//定义多项式的除法运算
//实质上也是乘以多项式在有限域的逆元
int GFpn::polynomial_div(int a,int b)
{
    int result;
    int aa = 0,bb = 0;
    int div_result = extent_gcd(M,b,aa,bb);
    result = polynomial_mul(a,aa);
    return result;
}

int main()
{
    GFpn gg;
    //srand()函数产生一个以当前时间开始的随机种子.以保证每次产生的随机数矩阵都不相同
    srand((unsigned)time(0));   
    cout << "给定多项式: " << gg.value_into_polynomial(M) << endl;
    cout << endl << "生成有限域......" << endl;
    cout << "以下是有限域内的所有元素:"<< endl;
    int i;
    for(i = 0;i < N;i++)
        cout << gg.value_into_polynomial(i) << endl;
    cout << endl;
    cout << "先从所构造的有限域中随机选取两个元素,分别为:" << endl;
    gg.random_element();
    cout << gg.value_into_polynomial(a) << " 和 " << gg.value_into_polynomial(b) << endl;
    cout << endl << "分别进行加减乘除运算:" << endl;
    cout << "加:" << "(" << gg.value_into_polynomial(a) << ") + (" << gg.value_into_polynomial(b) << ") = " 
        << gg.value_into_polynomial(gg.polynomial_add(a,b)) << endl;
    cout << endl;
    cout << "减:" << "(" << gg.value_into_polynomial(a) << ") - (" << gg.value_into_polynomial(b) << ") = " 
        << gg.value_into_polynomial(gg.polynomial_sub(a,b)) << endl;
    cout << endl;
    cout << "乘:" << "(" << gg.value_into_polynomial(a) << ") * (" << gg.value_into_polynomial(b) << ") = " 
        << gg.value_into_polynomial(gg.polynomial_mul(a,b)) << endl;
    cout << endl;
    cout << "除:" << "(" << gg.value_into_polynomial(a) << ") / (" << gg.value_into_polynomial(b) << ") = " 
        << gg.value_into_polynomial(gg.polynomial_div(a,b)) << endl;
    cout << endl;
    int a;
    cout << "是否还要继续:(按1退出)(按2继续)?" << endl;

    while(cin >> a && a != 1)
    {
        cout << "先从所构造的有限域中随机选取两个元素,分别为:" << endl;
        gg.random_element();
        cout << gg.value_into_polynomial(a) << " 和 " << gg.value_into_polynomial(b) << endl;
        cout << endl << "分别进行加减乘除运算:" << endl;
        cout << "加:" << "(" << gg.value_into_polynomial(a) << ") + (" << gg.value_into_polynomial(b) << ") = " 
            << gg.value_into_polynomial(gg.polynomial_add(a,b)) << endl;
        cout << endl;
        cout << "减:" << "(" << gg.value_into_polynomial(a) << ") - (" << gg.value_into_polynomial(b) << ") = " 
            << gg.value_into_polynomial(gg.polynomial_sub(a,b)) << endl;
        cout << endl;
        cout << "乘:" << "(" << gg.value_into_polynomial(a) << ") * (" << gg.value_into_polynomial(b) << ") = " 
            << gg.value_into_polynomial(gg.polynomial_mul(a,b)) << endl;
        cout << endl;
        cout << "除:" << "(" << gg.value_into_polynomial(a) << ") / (" << gg.value_into_polynomial(b) << ") = " 
            << gg.value_into_polynomial(gg.polynomial_div(a,b)) << endl;
        cout << endl;
        cout << "是否还要继续:(按1退出)(按2继续)?" << endl;
    }
    return 0;
}