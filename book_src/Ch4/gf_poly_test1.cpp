#include<iostream>
#include <cstdlib>
#include <ctime>
#include <string>
using namespace std;
/*
 *���ڶ���ʽ��,���ǿ�����һ��������������ʾ���м���
 *���磺x^3+x+1 �����Զ�������1011����ʾ,��ʮ��������11
 *���������Լ����ʽ x^8+x^4+x^3+x+1 ����ͨ���ö�������100011011����ʾ
 *��ʮ������283
 *��������ɵ�������GF(2^8)/(x^8+x^4+x^3+x+1),����2^8=256��Ԫ��
 */

//����һЩ����
const int M = 283;  //x^8+x^4+x^3+x+1
const int p = 2;   //ģ2
const int N = 256;  //�������ڵ�Ԫ�ظ���

int a,b;     //����������ѡȡ������Ԫ��

int remainvalue;  //����ʽ
int x,y;

class GFpn
{
public:
    //���������ڲ����ѡȡ����Ԫ��
    void random_element();

    //����һ��ʮ�������Ķ������������λ
    int index_of_binary_max(int value);

    //��һ��ʮ������ת��Ϊ��Ӧ�Ķ���ʽ�ַ���
    string value_into_polynomial(int value);

    //��һ������2����,������2^value.
    int power_of_value(int value);

    //���ض���ʽ�ĳ���,remainvalueΪ����
    int divide(int a,int b,int &remainvalue); 

    //�൱��ax - q * bx �ڶ���ʽ���ķ�����
    //��Ԫ������
    int Tx(int ax,int q,int bx);
    
    //��չ��ŷ������㷨
    //����x���ص���b mod m�Ķ���ʽ�ĳ˷���Ԫ
    //����Ӧ�ĵ�ʮ���������ʽ
    int extent_gcd(int m,int b,int &x,int &y);

    //�������ʽ�������ڵļӷ�����
    //ʵ�����������������
    int polynomial_add(int a,int b);

    //�������ʽ�������ڵļ�������
    //ʵ����Ҳ�������������
    int polynomial_sub(int a,int b);

    //�������ʽ�������ڵĳ˷�����
    //ͨ����λ,��ʵ����λ���
    int polynomial_mul(int a,int b);

    //�������ʽ�ĳ�������
    //ʵ����Ҳ�ǳ��Զ���ʽ�����������Ԫ
    int polynomial_div(int a,int b);
};

//�������������ѡȡ����Ԫ��
//�ȼ�Ϊ��0����N-1�����ѡȡ������
void GFpn::random_element()
{
    a = rand() % N;
    b = rand() % N;
}


//�����Ķ������������λ
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

//��һ����ת��Ϊ����ʽ
//�磺11����>1011����>x^3+x+1
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

//��һ������2����,������2^value.
int GFpn::power_of_value(int value)
{
    return 1 << (value);
}


//���ض���ʽ�ĳ���,remainvalueΪ����
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


//�൱��ax - q * bx �ڶ���ʽ���ķ�����
//��Ԫ������
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


//��չ��ŷ������㷨
int GFpn::extent_gcd(int m,int b,int &x,int &y)
{
    //�ȶ���(a1,a2,a3)��Ԫ��
    int a1 = 1,a2 = 0,a3 = m;
    //�ٶ���(b1,b2,b3)��Ԫ��
    int b1 = 0,b2 = 1,b3 = b;
    int remainvalue=0;
    while(1)
    {
        if(b3==0)
            return a3;
        if(b3==1)
            return b3;
        int q = divide(a3,b3,remainvalue);
        //�ֱ���(t1,t2,t3)��Ԫ��
        int t1 = Tx(a1,q,b1);     //q = a3 / b3;(����ʽ������)
        int t2 = Tx(a2,q,b2);     //t1<����a1 - q * b1
        int t3 = remainvalue;     //t2<����a2 - q * b2
        //��������  
        //(a1,a2,a3)<����(b1,b2,b3)
        a1 = b1;a2 = b2;a3 = b3;
        //(b1,b2,b3)<����(t1,t2,t3)
        b1 = t1;b2 = t2;b3 = t3;
        x = b2;
        y = b3; 
    }
}

//�������ʽ�������ڵļӷ�����
//ʵ�����������������
int GFpn::polynomial_add(int a,int b)
{
    int result;
    result = a ^ b;
    return result;
}

//�������ʽ�������ڵļ�������
//ʵ����Ҳ�������������
int GFpn::polynomial_sub(int a,int b)
{
    int result;
    result = a ^ b;
    return result;
}

//�������ʽ�������ڵĳ˷�����
//ͨ����λ,��ʵ����λ���
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

//�������ʽ�ĳ�������
//ʵ����Ҳ�ǳ��Զ���ʽ�����������Ԫ
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
    //srand()��������һ���Ե�ǰʱ�俪ʼ���������.�Ա�֤ÿ�β�������������󶼲���ͬ
    srand((unsigned)time(0));   
    cout << "��������ʽ: " << gg.value_into_polynomial(M) << endl;
    cout << endl << "����������......" << endl;
    cout << "�������������ڵ�����Ԫ��:"<< endl;
    int i;
    for(i = 0;i < N;i++)
        cout << gg.value_into_polynomial(i) << endl;
    cout << endl;
    cout << "�ȴ�������������������ѡȡ����Ԫ��,�ֱ�Ϊ:" << endl;
    gg.random_element();
    cout << gg.value_into_polynomial(a) << " �� " << gg.value_into_polynomial(b) << endl;
    cout << endl << "�ֱ���мӼ��˳�����:" << endl;
    cout << "��:" << "(" << gg.value_into_polynomial(a) << ") + (" << gg.value_into_polynomial(b) << ") = " 
        << gg.value_into_polynomial(gg.polynomial_add(a,b)) << endl;
    cout << endl;
    cout << "��:" << "(" << gg.value_into_polynomial(a) << ") - (" << gg.value_into_polynomial(b) << ") = " 
        << gg.value_into_polynomial(gg.polynomial_sub(a,b)) << endl;
    cout << endl;
    cout << "��:" << "(" << gg.value_into_polynomial(a) << ") * (" << gg.value_into_polynomial(b) << ") = " 
        << gg.value_into_polynomial(gg.polynomial_mul(a,b)) << endl;
    cout << endl;
    cout << "��:" << "(" << gg.value_into_polynomial(a) << ") / (" << gg.value_into_polynomial(b) << ") = " 
        << gg.value_into_polynomial(gg.polynomial_div(a,b)) << endl;
    cout << endl;
    int a;
    cout << "�Ƿ�Ҫ����:(��1�˳�)(��2����)?" << endl;

    while(cin >> a && a != 1)
    {
        cout << "�ȴ�������������������ѡȡ����Ԫ��,�ֱ�Ϊ:" << endl;
        gg.random_element();
        cout << gg.value_into_polynomial(a) << " �� " << gg.value_into_polynomial(b) << endl;
        cout << endl << "�ֱ���мӼ��˳�����:" << endl;
        cout << "��:" << "(" << gg.value_into_polynomial(a) << ") + (" << gg.value_into_polynomial(b) << ") = " 
            << gg.value_into_polynomial(gg.polynomial_add(a,b)) << endl;
        cout << endl;
        cout << "��:" << "(" << gg.value_into_polynomial(a) << ") - (" << gg.value_into_polynomial(b) << ") = " 
            << gg.value_into_polynomial(gg.polynomial_sub(a,b)) << endl;
        cout << endl;
        cout << "��:" << "(" << gg.value_into_polynomial(a) << ") * (" << gg.value_into_polynomial(b) << ") = " 
            << gg.value_into_polynomial(gg.polynomial_mul(a,b)) << endl;
        cout << endl;
        cout << "��:" << "(" << gg.value_into_polynomial(a) << ") / (" << gg.value_into_polynomial(b) << ") = " 
            << gg.value_into_polynomial(gg.polynomial_div(a,b)) << endl;
        cout << endl;
        cout << "�Ƿ�Ҫ����:(��1�˳�)(��2����)?" << endl;
    }
    return 0;
}