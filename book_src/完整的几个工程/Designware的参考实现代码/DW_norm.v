
// Description : DW_norm is a general-purpose normalization module for positive fractional input.
// The fixed-point input format is a = (a0.a1 a2 a3 a4... a(a_width-1), where ai represents a bit. 
// Input a has 1 integer bit and a_width-1 fractional bits. The normalization process consists in
// shifting the input vector a to the left until the output bit-vector has a 1 in the MS bit 
// position, or the vector has shifted by the maximum number of bits in the search window.
//
// The number of bit positions shifted to the left during normalization(n) is passsed to the value of 
// exp_adj. This output corresponds to (exp_offset + n) when parameter exp_ctr=0 or (exp_offset - n) 
// when exp_ctr = 1, where n=max(srch_wind-1, number of MS zeros).
//
//--------------------------------------------------------------------------------------------------

module DW_norm ( 
                  a,           //Input data
                  exp_offset,  //Offset value for the exponent
                  no_detect,   //Result of search for the leading bit with value 1 in the search
                               //window: 0 - bit found, 1 - bit not found 
                  ovfl,        //Value provided at output exp_adj is negative or incorrect
                  b,           //Normalized output data
                  exp_adj      //exp_offset combined with the no. of bit positions the input a was
                               //shifted to the left(n): exp_ctr=0 -> exp_offset+n; 
                               //exp_ctr=1 -> exp_offset-n
                  )/* synthesis syn_builtin_du = "weak" */;

	parameter a_width = 8;    //Word length of a and b
	parameter srch_wind = 8;  //Search window for the leading 1 bit(from bit position 0 to a_width-1)
      parameter exp_width = 4;  //Word length of exp_offset and exp_adj	
      parameter exp_ctr = 0;    //Control over exp_adj computation

      /************ Internal parameter *************/
      parameter size = (clogb2((srch_wind-1)/2)) + 1;
      /*********************************************/
      //input/output declaration
	input	[a_width-1:0]		a;
	input	[exp_width-1:0]		exp_offset;
	output				no_detect;
	output				ovfl;
	output [a_width-1:0]	      b;	
	output [exp_width-1:0]       	exp_adj;

	//internal decleration
    
      //Shift the input by srch_wind to know the prsence of leading '1'
      wire [size:0] cnt_plus = lzd_call(a[a_width-1:0]);
      wire [size-1:0] cnt = cnt_plus[size-1:0];
      wire no_detect = cnt_plus[size];
      wire [a_width-1:0] b = no_detect ? a << srch_wind-1 : a << cnt;
	wire [exp_width:0] temp =  exp_ctr ?  exp_offset - cnt : exp_offset + cnt;   
      wire [exp_width-1:0] exp_adj = temp[exp_width-1:0];
 //     wire ovfl = exp_ctr ? ~temp[exp_width] && (&cnt) : temp[exp_width];
      wire ovfl = temp[exp_width];

      //lzd: leading zero detector - Find the first '1' by shifting input to left 
	function [size:0] lzd_call; 
	  input [a_width-1:0]    inp_a;
	  reg                  flag;
	  reg   [size-1:0]     sh_cnt; 
	  integer              i;   
	  begin 
	    sh_cnt = srch_wind-1;//{size{1'b1}};
	    flag = 1'b1; 
	    for (i=0; i < srch_wind; i=i+1)	
		if ( inp_a[(a_width-1)-i] && flag )
		   begin 
		     flag = 0;
		     sh_cnt = i;
		   end	
		   lzd_call = {flag,sh_cnt};
	   end 		
	 endfunction 	   

	   //function to obtain bit width
	 function integer clogb2 (input integer depth);
	   begin
		   for(clogb2=0; depth>0; clogb2=clogb2+1)
			   depth = depth >> 1;
	   end
       endfunction

endmodule
