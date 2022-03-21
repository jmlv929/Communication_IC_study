
//----------------------------------------------------------------------------------


module lzd (a, count)/* synthesis syn_builtin_du = "weak" */;
		parameter a_width = 32;
		parameter size = 5;	 
		
		input [a_width-1:0] a;
		output [size-1:0] count;
		
		wire [size-1:0] count = lzd_call(a);	
		
		//lzd: leading zero detector - Find the first '1' by shifting input to left 
	   function [size-1:0] lzd_call; 
	   input [a_width-1:0]    inp_a;
	   reg                  flag;
	   reg   [size-1:0]     sh_cnt; 
	   integer              i;   
	   begin 
	           sh_cnt = 1;
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
     
	   endmodule
