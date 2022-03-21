#include<iostream>
using namespace std;

#define MaxpolyN 200

struct polyN{
	int n;
	double xi[MaxpolyN+1];
};

int max(int a,int b)
{
	if(a>b) return a;
	return b;
}
int check(polyN &a)
{
	while(a.n>0 && a.xi[a.n]==0) a.n--;

	return 0;
}
int show(polyN a)//find a problem in show;
{
	if(a.xi[a.n]==1)
	{
		if(a.n==0) cout<<1;
	}
	else if(a.xi[a.n]==-1) cout<<"-";
	else cout<<a.xi[a.n];

	if(a.n>1) cout<<"X^"<<a.n;
	if(a.n==1) cout<<"X";

	for(int i=a.n-1; i>=0; i--)
	{
		if(a.xi[i]>0)
		{
			if(a.xi[i]!=1) cout<<'+'<<a.xi[i];
			else if(i==0) cout<<"+1";
			  else cout<<'+';

			if(i>1) cout<<"X^"<<i;
			if(i==1) cout<<"X";
		}
		else if(a.xi[i]<0)
		{
			if(a.xi[i]!=-1) cout<<a.xi[i];
			else if(i==0) cout<<-1;
			else cout<<'-';

			if(i>1) cout<<"X^"<<i;
			if(i==1) cout<<"X";
		}
	}
	return 0;
}
bool GetpolyN(polyN &a)
{
	char s[MaxpolyN*10];
	polyN tmp={NULL};

	cin>>s;

	

	char lst='[';
	double xi=0; int zhi=0;
	int i=0;

	int len=strlen(s);
	s[len]='+',s[len+1]='\0';

	while(s[i]!='\0')
	{
		if(s[i]>='0' && s[i]<='9')
		{
			double num=0,dotcnt=1;
			bool isdot=false; 

			while(s[i]>='0' && s[i]<='9' || s[i]=='.' )
			{
				if(s[i]=='.')
				{
					if(isdot)
					{
						cout<<"小数点输入错误!"<<endl;
						return false;
					}else{
						isdot=true;
						dotcnt=1;
					}
				}else
				{
				if(isdot) dotcnt*=0.1;
				num=num*10+(s[i]-'0');
				}
				num=num*dotcnt;
				i++;
			}
			
			if(lst=='+' || lst=='[') xi=num; //xi
			else if(lst=='-'|| lst=='[') xi=-num;//-xi
			else if(lst=='^')//zhi
			{
				if(isdot)
				{
					cout<<"多项式的指数必须是正整数!"<<endl;
					return false;
				}
				zhi=int(num);
				if(zhi>=100)
				{
					cout<<"你的多项式输入次数太大了!"<<endl;
					return false;
				}
			}
			else
			{
				cout<<"你的输入有问题!"<<endl;
				return false;
			}
			i--;
		}else if(s[i]=='x' || s[i]=='X')
		{
			if(lst=='+' || lst=='[') xi=1;
			else if(lst=='-') xi=-1;
			  else if(lst>='0' && lst<='9')
			  {
			  }
				  else
			  {
				  cout<<"你的输入有误!"<<endl;
				  return false;
			  }
		}else if(s[i]=='^')
		{
			if(lst=='x' || lst=='X')
			{
			}else
			{
				cout<<"输入出错!"<<endl;
				return false;
			}
		}else if(s[i]=='+' || s[i]=='-')
		{
			if(lst>='0' && lst<='9' || lst=='[' || lst=='x' || lst=='X')
			{
				if(lst>='0' && lst<='9')
				{
					tmp.xi[zhi]+=xi;
				}else if(lst=='x' || lst=='X')
				{
					zhi=1;
					tmp.xi[zhi]+=xi;
				}

				tmp.n=max(tmp.n,zhi);
			}
				else 
			{
				cout<<"你的输入有问题!"<<endl;
				return false;
			}
			//fresh every thing;
			zhi=0;
			xi=0;
		}else
		{
			cout<<"你的输入有误!"<<endl;
			return false;
		}
		lst=s[i];
		i++;
	}


	check(tmp);
	a=tmp;

	return true;
}

polyN PLUS(polyN a,polyN b)
{
	polyN tmp={NULL}; 

	tmp.n=max(a.n,b.n);
	for(int i=tmp.n; i>=0; i--)
		tmp.xi[i]=a.xi[i]+b.xi[i];
	
	check(tmp);

	return tmp;
}

polyN SUB(polyN a,polyN b)
{
	polyN tmp={NULL};
	tmp.n=max(a.n,b.n);
	for(int i=tmp.n; i>=0; i--)
		tmp.xi[i]=a.xi[i]-b.xi[i];
	check(tmp);

	return tmp;
}
polyN MUL(polyN a,polyN b)
{
	polyN tmp={NULL};
	tmp.n=a.n+b.n;
	for(int i=a.n; i>=0; i--)
		for(int j=b.n; j>=0; j--)
			tmp.xi[i+j]+=a.xi[i]*b.xi[j];
	check(tmp);

	return tmp;
}

polyN DIV(polyN a,polyN b,polyN &rest)
{
	polyN s={NULL},r={NULL};

	if(b.n==0 && b.xi[0]==0) 
	{
		cout<<"除数不能为0!运算失败!"<<endl;
		return s;
	}

	r=a;

	if(r.n>=b.n) s.n=r.n-b.n;

	while(r.n>=b.n)
	{
		s.xi[r.n-b.n]=r.xi[r.n]/b.xi[b.n];

		r.xi[r.n]=0;

		for(int i=b.n-1; i>=0; i--)
			r.xi[i+r.n-b.n]-=b.xi[i]*s.xi[r.n-b.n];

		check(r);

		if(r.n==0 && r.xi[0]==0) break;
	}

	rest=r;

	return s;
}


#include"polyN.H"
#include<iostream>
using namespace std;

polyN a,b,u,v,d,sr;

void Egcd(int a,int b,int &x,int &y,int &d)
{
	if(b==0)
	{
		d=a;
		x=1; 
		y=0;
	}
	else
	{
		int x1,y1;
		Egcd(b,a%b,x1,y1,d);
		x=y1;
		y=x1-y1*(a/b);
	}
}

void Egcd_polyN(polyN a,polyN b,polyN &x,polyN &y,polyN &d)
{
	if(b.n==0 && b.xi[0]==0)
	{
		d=a;
		x.n=0; x.xi[0]=1;
		y.n=0; y.xi[0]=0;
	}
	else
	{
		polyN x1,y1,q;

		q=DIV(a,b,sr); 

		Egcd_polyN(b,sr,x1,y1,d);

		x=y1;
		y=SUB(x1,MUL(y1,q));
	}
	
	
}
void InitpolyN()
{
	bool Dget=false;
	while(!Dget)
	{
		cout<<"请输入第一个多项式:"<<endl;
		Dget=GetpolyN(a);
	}

	Dget=false;
	while(!Dget)
	{
		cout<<"请输入第二个多项式："<<endl;
		Dget=GetpolyN(b);
	}

	if(a.n<b.n) swap(a,b);
}
void check_GCD(polyN &d,polyN &u)
{
	int i;
	for( i=0; i<d.n; i++)
		d.xi[i]*=1/d.xi[d.n];
	for( i=0; i<=u.n; i++)
		u.xi[i]*=1/d.xi[d.n];
	d.xi[d.n]=1;
}
int main()
{
	InitpolyN();

	Egcd_polyN(a,b,u,v,d);

	check_GCD(d,u);
	check_GCD(d,v);
	show(d); cout<<endl;
	cout<<"("; show(a); cout<<")*";
	cout<<"("; show(u); cout<<")  +  ";
	cout<<"("; show(b); cout<<")*";
	cout<<"("; show(v); cout<<")   =";
	show(d); cout<<endl;
	system("pause");
	return 0;
}

