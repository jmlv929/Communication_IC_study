
//
//-------------------------------------------------------------------------------------------------
// Description : DW_lzd contains two outputs, dec and enc. The dec output is a decoded one-hot value
//of the a input vector assuming there is at least one "1" on a. The output enc represents
//the number of 0’s found (from the most significant bit) before the first occurrence of a "1"
//from the input port a. All lower order bits (to the right) from the first occurrence of the
//"1" on the a input port are "don't care". If no "1" is found and only 0's are present, the
//resulting value of enc is all 1's and of dec is all 0's.
//
//The output port enc width is automatically derived from the input port width parameter,
//a_width, and is defined as ceil(log2[a_width])+1 as listed in Table 1. Output port dec
//has the same width as the "a" input.
//-------------------------------------------------------------------------------------------------			
module DW_lzd (a, dec, enc)/* synthesis syn_builtin_du = "weak" */;
		parameter a_width = 32;
		parameter size = (clogb2((a_width-1)/2)) + 2;
		
            //Input/output declaration
		input  [a_width-1:0] a;
		output [a_width-1:0] dec;
		output [size-1:0]    enc;
		
            //Internal signal declaration
            reg [a_width-1:0]  dec;
            integer            i;

            //Implement lzd
		wire [size-1:0] enc = lzd_call(a);	
		wire [a_width-1:0] dec_out = 1'b1 << enc;

            //reverse the bits of dec_out
            always @(*)
              for ( i = 0; i < a_width; i = i + 1 )
                  dec[a_width-1-i] = dec_out[i];

	   //lzd: leading zero detector - Find the first '1' by shifting input to left 
	   function [size-1:0] lzd_call; 
	   input [a_width-1:0]  inp_a;
	   reg                  flag;
	   reg   [size-1:0]     sh_cnt; 
	   integer              i;   
	   begin 
	         sh_cnt = {size{1'b1}};
			   flag = 1'b1; 
			   for (i=a_width-1; i>=0; i=i-1)	
				   if ( inp_a[i] && flag )
					   begin 
						   flag = 0;
						   sh_cnt = (a_width-1)-i;
					   end	
			   lzd_call = sh_cnt;
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
