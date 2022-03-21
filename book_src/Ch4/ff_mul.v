// 有限域GF(28)弱对偶基乘法器 
// 本原多项式: p(x) = x^8 + x^4 + x^3 + x^2 + 1  
// 多项式基: 	{1, a^1, a^2, a^3, a^4, a^5, a^6, a^7} 
// 弱对偶基:	{1+a^2, a^1, 1, a^7, a^6, a^5, a^4, a^3+a^7} 
`define M	8 
module ff_mul(din1, din2, dout, dual_base); 
	//parameter	CONST = 8'h3b; 
 
	input  [`M-1:0]	din1, din2;		// din2需要转换到弱对偶基 
	output [`M-1:0]	dout; 
	output [2*`M-2:0] dual_base; 
	reg    [`M-1:0]	dout; 
 
	reg	[2*`M-2:0]	dual_base; 
	reg [`M-1:0]	temp; 
	always @(din1 or din2)begin: Block1 
	 integer i; 
		  // 多项式基到对偶基坐标变换 
		  dual_base[0] = din2[0] ^ din2[2]; 
		  dual_base[1] = din2[1]; 
		  dual_base[2] = din2[0]; 
		  dual_base[3] = din2[7]; 
		  dual_base[4] = din2[6]; 
		  dual_base[5] = din2[5]; 
		  dual_base[6] = din2[4]; 
		  dual_base[7] = din2[3] ^ din2[7]; 
		 
		  // 对偶基扩展 
		  for(i=0; i<`M-1; i=i+1) begin 
				dual_base[`M+i] = dual_base[0+i] ^ dual_base[2+i] ^  
										dual_base[3+i] ^ dual_base[4+i]; 
		  end 
		 
		  // 多项式基与对偶基相乘 
		  for(i=0; i<`M; i=i+1) begin 
		    temp[i]=(((dual_base[i+0]&din1[0])^ (dual_base[i+1]&din1[1]))  
					^((dual_base[i+2]&din1[2]) ^(dual_base[i+3]&din1[3]))) 
					^(((dual_base[i+4]&din1[4])^(dual_base[i+5]&din1[5])) 
					^((dual_base[i+6]&din1[6]) ^ (dual_base[i+7]&din1[7]))); 
		  end 
		 
		  // 将乘法结果从对偶基变换到多项式基 
		  dout[0] = temp[2];												 
		dout[1] = temp[1]; 
		  dout[2] = temp[0] ^ temp[2]; 
		  dout[3] = temp[3] ^ temp[7]; 
		  dout[4] = temp[6]; 
		  dout[5] = temp[5]; 
		  dout[6] = temp[4]; 
		  dout[7] = temp[3];												 
end 
endmodule 

