// 常系数有限域乘法器 
// 本原多项式: p(x) = x^8 + x^4 + x^3 + x^2 + 1  
// 多项式基: 	{1, a^1, a^2, a^3, a^4, a^5, a^6, a^7} 
// 弱对偶基:	{1+a^2, a^1, 1, a^7, a^6, a^5, a^4, a^3+a^7} 
`define M	8 
module ff_const_mul(din, dout); 
	parameter	CONST = 15'h0CE7; 
 
	input  [`M-1:0]	din;	 
	output [`M-1:0]	dout; 
 
	wire   [2*`M-2:0]	dual_base; 
	assign 	dual_base = CONST; 
 
	reg [`M-1:0]	dout, temp; 
	always @(din or dual_base)begin: Block1 
		integer i; 
		// 乘法运算 
		for(i=0; i<`M; i=i+1) begin 
			temp[i]=(((dual_base[i+0]&din[0]) ^(dual_base[i+1]&din[1]))  
					  ^((dual_base[i+2]&din[2]) ^(dual_base[i+3]&din[3]))) 
					  ^(((dual_base[i+4]&din[4])^(dual_base[i+5]&din[5])) 
					  ^((dual_base[i+6]&din[6]) ^(dual_base[i+7]&din[7]))); 
		end 
		 
		// 弱对偶基到多项式基变换 
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

