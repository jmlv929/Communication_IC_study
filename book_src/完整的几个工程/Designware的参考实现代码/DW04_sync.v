

//////// RTL for DW04_sync starts here ///////
module DW04_sync(async, ref_clk, reset, sync, error ) /* synthesis syn_builtin_du = "weak" *//* synthesis syn_preserve= 1 */;

parameter num_async = 16;
parameter redund = 2;

input [num_async-1 : 0]async;
input ref_clk,reset;

output error;
output [num_async-1:0]sync;

reg error;
reg [num_async-1:0]sync /* synthesis syn_preserve = 1 */ ;
reg [num_async-1:0] tempout  /* synthesis syn_preserve = 1 */ ;
reg [num_async-1:0] tempout1 /* synthesis syn_preserve = 1 */ ;
reg [num_async-1:0] tempout2 /* synthesis syn_preserve = 1 */ ;
reg errorout;
wire [1:0]redund_sig;


assign redund_sig=redund;

always @(negedge reset or posedge ref_clk )
begin
 
if (!reset)
	begin
	tempout <= 'b0;
	tempout1 <= 'b0;
    tempout2 <= 'b0;
			
	end
else				begin
				tempout<=async;
				tempout1 <= async;
				tempout2 <= async;
				
				end

end

always @( negedge reset or posedge ref_clk)
begin: example
integer i;
integer j;

if (!reset)
sync<= 'b0;

else 
	begin
		if (redund_sig==2'b11)
						  begin     
 								//synthesis loop_limit 2000 
					  			for (i=0;i<=num_async-1;i=i+1)
								begin
							  		if (tempout[i]==tempout1[i])      
						  			    sync[i]<=tempout[i];        
									else if (tempout1[i]==tempout2[i])
						  			    sync[i]<=tempout1[i];       
						  			else                        
						  			    sync[i]<=tempout2[i];
       						     end
					  	  end 			
			
		else if (redund_sig==2'b10)		
						begin
              //synthesis loop_limit 2000
							for (j=0;j<=num_async-1;j=j+1)
							begin
								if (tempout[j]==tempout1[j])
								sync[j]<=tempout[j];
								
							end
						end
			
		else
			   		sync<=tempout;		
				
			
		
		end

end




always @(reset or redund_sig or tempout or tempout1 or tempout2)
begin	
	if (reset == 1'b0)
		errorout=1'b0;
	else
	begin
		if (redund_sig==2'b01)
			errorout=1'b0;
		else if (redund_sig==2'b10)
			begin
				if (tempout==tempout1)
				errorout=1'b0;
				else
				errorout=1'b1;
			end
		else
			begin
			if ((tempout==tempout1)&& (tempout==tempout2))
				errorout= 1'b0;
			else
				errorout= 1'b1;
			end		
	end	

error = errorout;
end

endmodule
