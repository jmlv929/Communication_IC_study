

//--------------------------------------------------------------------------------------------------
//
// Title       : DW02_sqrt
// Design      : DW02_sqrt

// Company     : 
//-------------------------------------------------------------------------------------------------
// Description : DW02_sqrt computes the integer square root of A. The signal TC determines whether 
// the input is interpreted as unsigned ( TC is low) or signed ( TC is high), when the parameter 
// TC_mode is equal to 1.
//
//-------------------------------------------------------------------------------------------------

module DW02_sqrt ( A, TC, ROOT )/* synthesis syn_builtin_du = "weak" */;
	parameter width = 32;
	parameter TC_mode = 1;
	
	//Internally generated parameters
	parameter	count   = width / 2;
	parameter   add     = width % 2;
	parameter   part    = count + add;
	parameter   total   = width + add;
	
	//Input/Output port declaration
	input	[width - 1 : 0]   A;	   
	input                     TC;
	
	output	[ part- 1 : 0 ]   ROOT;
	
	//Internal register declaration
	reg		[ total/2 + total  - 1 : 0 ]partial_root;
	reg		[ total - 1 : 0 ]           tmp_a;
	reg		[width - 1 : 0]		        a;	
	integer	                            i;
	
	reg	[part : 0]                      quo;
	reg [part + 2 - 1 : 0]				initial_reg;
	reg [part + 2 - 1 : 0]				add_value;
	reg [part + 2 - 1 : 0]				sum;
	reg [part + 2 - 1 : 0]				added;
    reg                                 add_flag ;	
	
	//Taking care of -ve input
	always@(TC or A) 
		if(TC_mode)
			begin	
				if( TC & (A[width-1]) )
					a = ~A + 1;
				else
					a = A;
			end	
		else	
			a = A;
			
    //Converting odd width to event width by appending 0's to MSB
	always@(a)
		if( total != width)
			tmp_a = {1'b0,a};
		else
			tmp_a = a;	
	
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
					add_value=~add_value+1;	                                                        
				end	                                                                                
				                                                                                    
				partial_root = partial_root << 2;                                                   
				                                                                                    
		    end	
	    end			  
	
assign ROOT = quo[part:1];	

endmodule
