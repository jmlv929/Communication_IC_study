

//// RTL for DW01_binenc /////
module DW01_binenc(A, ADDR)/* synthesis syn_builtin_du = "weak" */;
parameter A_width = 32;
parameter ADDR_width = 6;

output [ADDR_width-1:0]ADDR;

input [A_width-1:0]A;
reg [ADDR_width-1:0]ADDR;

always @(A)
          begin : local
                integer i;
               /* returns the value of the highest bit number turned on */
               if (A==0) 
				   		
		 		   ADDR = (32'b1<< ADDR_width) -1 ;
			   else
				   begin   
				   // synthesis loop_limit 2000  
			         for (i = A_width-1 ; i >= 0; i = i -1) 
                        	begin
                        		if (A[i]) 
					               begin
			                          ADDR = i;
									  
								   end
							     
							end
                   end
		 	  
		    end
 
endmodule
