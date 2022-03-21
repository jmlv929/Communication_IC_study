

///////// RTL for DW03_bictr_decode starts here /////////
module DW03_bictr_decode (data, up_dn, load, cen, clk, reset, count_dec, tercnt)/* synthesis syn_builtin_du = "weak" */;

parameter width = 3;

input [width-1:0] data;
input up_dn;
input load;
input cen;
input clk;
input reset;
output [(1<<width)-1:0] count_dec;
output tercnt;
reg [width-1:0] count_i;
wire tercnt;

//Binary counter implementation
always @ (posedge clk or negedge reset)
	if (!reset )
		count_i <= 0;
	else 
		begin
			if (!load)
				count_i <= data;
			else if (cen)
				begin
					if(up_dn)
						count_i <= count_i + 1;
					else
						count_i <= count_i - 1;
				end		   
		end
      		
assign tercnt = up_dn ? (count_i == {width{1'b1}}) : (count_i == 0); 
assign count_dec = 1'b1 << count_i; 	

endmodule
