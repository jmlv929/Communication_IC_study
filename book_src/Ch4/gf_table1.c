int table[256];  
int i;  
  
table[0] = 1;//g^0  
for(i = 1; i < 255; ++i)//生成元为x + 1  
{  
    //下面是m_table[i] = m_table[i-1] * (x + 1)的简写形式  
    table[i] = (table[i-1] << 1 ) ^ table[i-1];  
  
	    //最高指数已经到了8，需要模上m(x)  
	    if( table[i] & 0x100 )  
	    {  
	        table[i] ^= 0x11B;//用到了前面说到的乘法技巧  
	    }  
}
  
