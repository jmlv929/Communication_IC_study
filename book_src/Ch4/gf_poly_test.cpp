#include "stdafx.h"
#include <iostream>
#include <vector>
#include <algorithm>
#include <fstream>
#include <math.h>

using namespace std;

typedef struct polyNode//多项式节点项
{
    int coef;
    int power;
}polyNode;

void CreatePoly(vector<polyNode>&poly);//构造多项式
void SortPolyByPower(vector<polyNode>&poly);//对多项式排序，按照降幂
vector<polyNode> PolyAdd(vector<polyNode>p1,vector<polyNode>p2);//多项式加法
vector<polyNode> PolySub(vector<polyNode>p1,vector<polyNode>p2);//多项式减法
vector<polyNode> PolyMultiply(vector<polyNode>p1,vector<polyNode>p2);//多项式乘法
vector<polyNode> PolyDiv(vector<polyNode>&p1,vector<polyNode>p2);//多项式除法
vector<polyNode> Eculid(vector<polyNode>&p1,vector<polyNode>&p2);//扩展欧几里得算法


void SortPolyByPower(vector<polyNode>&poly)//OK
{
    vector<polyNode>::iterator iter,tmpIter;
    iter = poly.begin();
    for (; iter != poly.end(); iter++)//按照幂数高低排序
    {
        tmpIter = iter + 1;
        int maxPower = (*iter).power;
        for (; tmpIter != poly.end(); tmpIter++)
        {
            if ((*tmpIter).power > (*iter).power)
            {
                iter_swap(iter,tmpIter);
            }
        }    
    }

}

void CreatePoly(vector<polyNode>&poly)//OK
{
    static int itemCount = 0;
    cout<<"Please input the itemCount of the poly:"<<endl;
    cin>>itemCount; 
    for (int t = 0; t < itemCount; t++)
    {
        static polyNode tmpItem;
        cout<<"Please input the coef and power:"<<endl;
        cin>>tmpItem.coef>>tmpItem.power;
        poly.push_back(tmpItem);

    }
    SortPolyByPower(poly);
    cout<<"原始多项式为："<<endl;
    vector<polyNode>::iterator iter;
    for ( iter = poly.begin();iter!= poly.end();iter++)
    {
        cout<<"X^"<<(*iter).power<<"+";
    }
    cout<<endl;
}

vector<polyNode> PolyAdd(vector<polyNode>p1,vector<polyNode>p2)//OK
{
    vector<polyNode> tmpPolyAdd;
    vector<polyNode>::iterator iter1,iter2;
    iter1 = p1.begin();
    iter2 = p2.begin();
    if (p1.size() == 0)
    {
        tmpPolyAdd.clear();
        tmpPolyAdd = p2;
        return tmpPolyAdd;
    }
    else if(p2.size() == 0)
    {
        tmpPolyAdd.clear();
        tmpPolyAdd = p1;
        return tmpPolyAdd;
    }
    else
    {
        tmpPolyAdd.clear();
        for (; iter1 != p1.end() && iter2 != p2.end();)
        {
            if ((*iter1).power > (*iter2).power)
            {
                tmpPolyAdd.push_back(*iter1);
                iter1++;
            }
            else if ((*iter1).power == (*iter2).power)
            {
                polyNode tmp;
                tmp.coef = ((*iter1).coef + (*iter2).coef)%2;
                tmp.power = (*iter1).power;
                if (tmp.coef != 0)
                {
                    tmpPolyAdd.push_back(tmp);
                }
                else;
                iter1++;
                iter2++;
            }
            else if ((*iter1).power < (*iter2).power)
            {
                tmpPolyAdd.push_back(*iter2);
                iter2++;
            }
        }
        if (iter2 != p2.end())
        {
            for (;iter2 != p2.end();iter2++)
            {
                tmpPolyAdd.push_back(*iter2);
            }
            SortPolyByPower(tmpPolyAdd);
            return tmpPolyAdd;
        }
        else if(iter1 != p1.end())
        {
            for (;iter1 != p1.end();iter1++)
            {
                tmpPolyAdd.push_back(*iter1);
            }
            SortPolyByPower(tmpPolyAdd);
            return tmpPolyAdd;
        }
        else 
        {
            SortPolyByPower(tmpPolyAdd);
            return tmpPolyAdd;
        }

    }
}

vector<polyNode> PolySub(vector<polyNode>p1,vector<polyNode>p2)//OK
{
    vector<polyNode> tmpPolySub;
    vector<polyNode>::iterator iter1,iter2;
    iter1 = p1.begin();
    iter2 = p2.begin();
    for (; iter1 != p1.end() && iter2 != p2.end();)
    {
        if ((*iter1).power > (*iter2).power)
        {
            tmpPolySub.push_back(*iter1);
            iter1++;
        }
        else if ((*iter1).power == (*iter2).power)
        {
            polyNode tmp;
            tmp.coef = ((*iter1).coef - (*iter2).coef)%2;
            tmp.power = (*iter1).power;
            if (tmp.coef != 0)
            {
                tmpPolySub.push_back(tmp);
            }
            else;

            iter1++;
            iter2++;
        }
        else if ((*iter1).power < (*iter2).power)
        {
            tmpPolySub.push_back(*iter2);
            iter2++;
        }
    }
    if (iter2 == p2.end())
    {
        for (;iter1 != p1.end();iter1++)
        {
            tmpPolySub.push_back(*iter1);
        }
    }
    else if(iter1 == p1.end())
    {
        for (;iter2 != p2.end();iter2++)
        {
            tmpPolySub.push_back(*iter2);
        }
    }
    SortPolyByPower(tmpPolySub);
    return tmpPolySub;
}

vector<polyNode> PolyMultiply( vector<polyNode>p1, vector<polyNode>p2)//OK
{
    vector<polyNode> tmpPolyMul;
    tmpPolyMul.clear();
    vector<polyNode> itemPoly;
    polyNode tmp;

    vector<polyNode>::iterator iter1,iter2;
    iter1 = p1.begin();
    iter2 = p2.begin();
    for (; iter2 != p2.end(); iter2++)
    {
        for (;iter1 != p1.end(); iter1++)
        {
            tmp.coef = (*iter1).coef * (*iter2).coef;
            tmp.power = (*iter1).power + (*iter2).power;
            itemPoly.push_back(tmp);
        }
        SortPolyByPower(itemPoly);
        iter1 = p1.begin();        
        tmpPolyMul = PolyAdd(tmpPolyMul,itemPoly);
        itemPoly.clear();
    }
    SortPolyByPower(tmpPolyMul);
    return tmpPolyMul;

}

vector<polyNode> PolyDiv(vector<polyNode>&p1, vector<polyNode>p2)//OK
{
    polyNode tmpItem;
    vector<polyNode> tmpP1 = p1;
    vector<polyNode> tmpP2 = p2;
    static vector<polyNode> result;
    static vector<polyNode> ret;
    vector<polyNode> tmpMultiply;
    vector<polyNode> tmpResult;
    static vector<polyNode> rPoly;

    vector<polyNode>::iterator iter1;
    vector<polyNode>::iterator iter2;
    iter1 = tmpP1.begin();
    iter2 = tmpP2.begin();
    while ((*iter1).power >= (*iter2).power)
    {
        for (;iter2!=tmpP2.end();iter2++)
        {
            tmpItem.coef = abs((*iter1).coef / (*iter2).coef);
            tmpItem.power = (*iter1).power - (*iter2).power;
            tmpResult.push_back(tmpItem);
            result.push_back(tmpItem);

            tmpMultiply = PolyMultiply(p2,tmpResult);
            vector<polyNode>::iterator tmpIter;
            tmpIter = tmpMultiply.begin();
            tmpResult.clear();
            rPoly= PolySub(tmpP1,tmpMultiply);

            p1 = rPoly;
            rPoly.clear();
            return PolyDiv(p1,p2);
        }
    }
    SortPolyByPower(result);
    ret = result;
    result.clear();
    return ret;
}

vector<polyNode> Eculid(vector<polyNode>&mx,vector<polyNode>&bx)//OK
{
    vector<polyNode> a1x;
    vector<polyNode> a2x;
    vector<polyNode> a3x;
    vector<polyNode> a3xcp;

    vector<polyNode> b1x;
    vector<polyNode> b2x;
    vector<polyNode> b3x;

    vector<polyNode> t1x;
    vector<polyNode> t2x;
    vector<polyNode> t3x;

    vector<polyNode> qx;
    vector<polyNode> gcd;
    vector<polyNode> inverse;
    vector<polyNode>::iterator iter;

    static polyNode tmpItem;
    tmpItem.coef = 1;
    tmpItem.power = 0;
    a1x.push_back(tmpItem);
    a3x.clear();
    a3x = mx;

    b1x.clear();
    tmpItem.coef = 1;
    tmpItem.power = 0;
    b2x.push_back(tmpItem);
    b3x = bx;
    do 
    {
        iter = b3x.begin();
        if (b3x.empty())
        {
            cout<<"No inverse!!!"<<endl;
            exit(0);
        }
        else if (b3x.size() == 1 && ((*iter).coef == 1 && (*iter).power == 0))
        {
            inverse = b2x;
            return inverse;
        }
        a3xcp = a3x;
        qx = PolyDiv(a3x,b3x);
        a3x = a3xcp;

        t1x = PolySub(a1x,PolyMultiply(qx,b1x));
        t2x = PolySub(a2x,PolyMultiply(qx,b2x));
        t3x = PolySub(a3x,PolyMultiply(qx,b3x));

        a1x = b1x;
        a2x = b2x;
        a3x = b3x;

        b1x = t1x;
        b2x = t2x;
        b3x = t3x;
    } while (1);

}


int main()
{
    vector<polyNode> polynomial1;
    vector<polyNode> polynomial2;
    vector<polyNode> inverse;
    vector<polyNode> ::iterator iter;
    vector<polyNode> r;
    CreatePoly(polynomial1);
    CreatePoly(polynomial2);
    inverse = Eculid(polynomial1,polynomial2);
    SortPolyByPower(inverse);
    iter = inverse.begin();
    cout<<"求得的逆为："<<endl;
    for (;iter!=inverse.end();iter++)
    {
        cout<<"X^"<<(*iter).power<<"+"<<endl;
    }
    getchar();

}