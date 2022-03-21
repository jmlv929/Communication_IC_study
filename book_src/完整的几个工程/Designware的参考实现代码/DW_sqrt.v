
//--------------------------------------------------------------------------------------------------
//
// Title       : DW_sqrt
// Design      : DW_sqrt

// Company     : 
//-------------------------------------------------------------------------------------------------
// Description : Combinational Square Root : DW_sqrt computes the integer square root of a. The 
// parameter tc_mode determines whether the input a is interpreted as unsigned (tc_mode=0) or two's 
// complement (tc_mode = 1) number.
//
//-------------------------------------------------------------------------------------------------
`timescale 1 ns / 10 ps

module DW_sqrt ( root, a )/* synthesis syn_builtin_du = "weak" */;
	parameter width = 32;
	parameter tc_mode = 1;
	
	//Internally generated parameters
	parameter	count   = width / 2;
	parameter   add     = width % 2;
	parameter   part    = count + add;
	parameter   total   = width + add;
	
	//Input/Output port declaration
	input	[width - 1 : 0]   a;	   
	
	output	[ part- 1 : 0 ]   root;
	
	//Internal register declaration
	reg		[ total/2 + total  - 1 : 0 ]partial_root;
	reg		[ total - 1 : 0 ]           tmp_a;
	reg		[width - 1 : 0]		        a_2s;	
	integer	                            i;
	
	reg	[part : 0]                      quo;
	reg [part + 2 - 1 : 0]				initial_reg;
	reg [part + 2 - 1 : 0]				add_value;
	reg [part + 2 - 1 : 0]				sum;
	reg [part + 2 - 1 : 0]				added;
    reg                                 add_flag;	
	
	//Taking care of -ve input
	always@(a) 
		if(tc_mode)
			begin	
				if( a[width - 1] )
					a_2s = ~a + 1;
				else
					a_2s = a;
			end	
		else	
			a_2s = a;
			
    //Converting odd width to even width by appending 0's to MSB
	always@(a_2s)
		if( total != width)
			tmp_a = {1'b0,a_2s};
		else
			tmp_a = a_2s;	
	
	//Procedual block to obtain the square root		
    always@(tmp_a)
		begin		   
			partial_root = { { ( (part+total) - total ) {1'b0} } , tmp_a };
			initial_reg = { {part{1'b0}} ,{2'b01}};                                                  
			add_value = ~initial_reg + 1;                                                           
			quo = 0;                                                                                
			add_flag = 0; 
      // synthesis loop_limit 2000                                                                
			for(i = 0; i < part; i = i + 1)                                                                   
			begin                                                                                   
				added = partial_root[total + part - 1 : total - 2 ];                                       
				sum = added + add_value;                                                            
				if(sum[part + 2 - 1])                                                                   
				begin                                                                               
					quo[0]=0;								                                        
					add_flag = 1;                                                                   
				end	                                                                                
				else                                                                                
				begin                                                                               
					quo[0]=1;                                                                       
					add_flag = 0;                                                                   
				end	                                                                                
				                                                                                    
				partial_root[(total + part) - 1 : total - 2]=sum;                                           
				add_value[part + 2 - 1 : 2]= quo[part - 1 : 0];                                                
				quo = quo << 1;                                                                  

				if(add_flag)                                                                        
				begin                                                                               
					add_value[1]=1;                                                                 
					add_value[0]=1;                                                                 
					add_value=add_value;	                                                        
				end                                                                                 
				else                                                                                
				begin                                                                               
					add_value[1]=0;                                                                 
					add_value[0]=1;                                                                 
					add_value=~add_value + 1;                 
				end	                                                                                
				                                                                                    
				partial_root = partial_root << 2;                                                   
				                                                                                    
		    end	
	    end			  
	
assign root = quo[part:1];	

endmodule
