	 
  //--------------------------------------------------------------------------------------------------
//
// Title       : DW02_tree
// Design      : Wallace Tree Compressor

//-------------------------------------------------------------------------------------------------
//
// Description : DW02_tree is a Wallace-tree compressor. This component is used in building the
// Wallace-tree adder, DW02_sum. DW02_tree is included as a separate component for
// designing your own hierarchical summation blocks or Wallace-tree-based multipliers. 
//
//-------------------------------------------------------------------------------------------------
module DW02_tree (INPUT, OUT0, OUT1 )/* synthesis syn_builtin_du = "weak" */;
parameter num_inputs = 2;
parameter input_width  = 2;	 

input	[ num_inputs * input_width - 1 : 0]	INPUT; //Input vector
output	[ input_width - 1 : 0 ]		        OUT0; //Partial sum 
output	[ input_width - 1 : 0 ]		        OUT1; //Partial sum 

//Internal signal declaration
reg  [ num_inputs * input_width - 1 : 0 ] reg_hold;
reg  [ num_inputs * input_width - 1 : 0 ] main_hold;
reg	[ input_width - 1 : 0 ]		          OUT0; 
reg	[ input_width - 1 : 0 ]		          OUT1; 


//Wallace tree using CSA
always@(INPUT)
begin 
	reg_hold	=	INPUT;
	
	if ( num_inputs == 2 )
		begin
			main_hold[input_width - 1 : 0] = INPUT[input_width-1 : 0];
			main_hold[2 * input_width - 1:input_width] = INPUT[num_inputs*input_width-1: input_width];
		end	
	else if ( num_inputs == 1 )
		begin
		   if ( input_width == 1 )
             main_hold = reg_hold;
		   else //if ( input_width == 2 )
             main_hold[input_width - 1 : 0] = reg_hold[num_inputs * input_width - 1 : 0];
		end
	else
	begin : inner
 	    reg	 [ 2*input_width - 1 : 0] 			  temp;
        reg	 [ input_width - 1 : 0 ]			  a;			 
        reg	 [ input_width - 1 : 0 ]			  b;			 
        reg	 [ input_width - 1 : 0 ]			  c;			 

	    integer j;
        integer cnt;
        integer t;
        integer k;
        integer l;
        integer remi;
        integer tt;

		reg 	[num_inputs * input_width - 1 : 0] hold;
		reg     [num_inputs * input_width - 1 : 0] tmp_hold;
		
		hold = 0;  
		tmp_hold = 0;
	    hold = reg_hold;
		// synthesis loop_limit 2000  
		for ( cnt = num_inputs; cnt >= 3; cnt = t * 2 + remi )
		begin
			t = cnt / 3 ;		
			remi = cnt % 3 ;
			    // synthesis loop_limit 2000  
				for( j = 0 ; j < t ; j = j + 1 )                                                       
				begin									                                               
				  // synthesis loop_limit 2000                                                                                       
				  for( k = 0 ; k < input_width ; k = k + 1 )                                                    
				  begin	                                                                               
				    a[ k ] = hold[ j * 3 * input_width + k ];                                                     
				    b[ k ] = hold[ j * 3 * input_width + input_width + k ];                                              
				    c[ k ] = hold[ j * 3 * input_width + input_width + input_width + k ];                                       
				  end                                                                                    
				                                                                                       
				  temp = csa_adder( c , b , a );                                                         
				   // synthesis loop_limit 2000	                                                                                       
				  for( l = 0 ; l < 2 * input_width  ; l = l + 1 )                                               
				  begin	                                                                               
				    tmp_hold[ j * 2 * input_width + l ]= temp[ l ];                                                
				  end			                                                                           
				                                                                                       
				end		                                                                               
				//cnt = t * 2 + remi;				                                                       
				if ( remi > 0 )    
                // synthesis loop_limit 2000                                                                   
				  for(tt = 0 ; tt < remi * input_width ; tt = tt + 1)                                             
					tmp_hold[ t * 2 * input_width + tt ] = hold[t * 3 * input_width + tt];                                 
					                                                                                   
				hold = tmp_hold;	                                                                   
		end //while	
	
		main_hold = hold[2*input_width-1:0];	
	end //else		
end	//always
		
//Updating outputs
always @ ( main_hold )
if ( input_width == 1 )
begin
   OUT1 =  0;
   OUT0 =  main_hold[0];
end
else if ( num_inputs == 1)
begin
   OUT1 =  0;	
   OUT0 =  main_hold[input_width - 1 : 0];
end
else
begin
   OUT1 =  main_hold[2 * input_width - 1 : input_width];	
   OUT0 =  main_hold[input_width - 1 : 0];
end

//n-bit CSA adder
function [ 2 * input_width - 1 : 0 ]csa_adder;
 input	[ input_width - 1 : 0 ]	a;
 input	[ input_width - 1 : 0 ]	b;
 input	[ input_width - 1 : 0 ]	c;
 integer 					i;
 reg 						su,ca;	  
 begin
 // synthesis loop_limit 2000  
	for( i = 0 ; i < input_width ; i = i + 1 )
	begin
		{ ca ,su }			=	csa(a[i], b[i], c[i]);
		csa_adder[ i ]		=	su;
		csa_adder[ input_width + i]=	ca;
	end				   
	csa_adder = { csa_adder[2*input_width - 1 : input_width] << 1 , csa_adder[input_width - 1 : 0]} ;
 end	 	
endfunction

//1-bit CSA adder
function [ 1 : 0 ]csa;
input	a, b, c;
begin
//	csa[1:0] = a + b + c;   
	csa [ 0 ] =  a  ^  b  ^  c ;
	csa [ 1 ] = a&b | b&c | c&a;
end
endfunction

endmodule
