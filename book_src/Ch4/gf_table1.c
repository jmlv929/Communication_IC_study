int table[256];  
int i;  
  
table[0] = 1;//g^0  
for(i = 1; i < 255; ++i)//����ԪΪx + 1  
{  
    //������m_table[i] = m_table[i-1] * (x + 1)�ļ�д��ʽ  
    table[i] = (table[i-1] << 1 ) ^ table[i-1];  
  
	    //���ָ���Ѿ�����8����Ҫģ��m(x)  
	    if( table[i] & 0x100 )  
	    {  
	        table[i] ^= 0x11B;//�õ���ǰ��˵���ĳ˷�����  
	    }  
}
  
