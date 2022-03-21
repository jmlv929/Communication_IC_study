
// ---------------------------------------------------------
//  Divider Module
// ---------------------------------------------------------
module div_int # (
		  parameter a_width     =   32,
			    b_width     =   32,
			    rst_mode    =   0,
			    stall_mode  =   1,
			    num_adders  =   4
		 )
		 (
		  input               rst_n,
		  input               clk,
		  input               en,

		  input [a_width-1:0] dividend,
		  input [b_width-1:0] b_int,
		  input [b_width:0]   sum,
		  input div_by_0,


		  output  [b_width:0] sum_r,
		  output  [a_width-1:0] dividend_r,
		  output  div_by_0_r
		  );
wire [a_width+b_width : 0 ] s_int_res;wire [a_width+b_width : 0 ] s_int_reg;
reg [a_width-1:0] quot_par;
reg [b_width:0]   rem_par;

reg [a_width - 1 : 0 ] dividend_int;                                                      
reg [b_width : 0 ] sum_int;//width = B_width + 1                                          
reg [b_width : 0 ] temp_b;//width = B_width + 1                                           
integer i;

// Division Implementation
// Shift and add non restoring Algorithm
always @ *
   begin                                                                                  
      sum_int = sum;                                                                      
      dividend_int = dividend;
      for ( i = 0; i < num_adders; i = i + 1 )                                            
	 begin                                                                            
	   if ( sum_int[b_width] )// 1 = -ve, 0 = +ve                                     
	      temp_b = b_int;
	   else                                                                           
	      temp_b = ~b_int + 1'b1;

	    sum_int = sum_int << 1'b1;                                                    
	    sum_int[0] = dividend_int[a_width - 1];                                       
	    sum_int = sum_int + temp_b;                                                   

	    dividend_int = dividend_int << 1'b1;                                          
	    dividend_int[0] = ~sum_int[b_width];                                          
	  end                                                                             
	    rem_par  =  sum_int;
	    quot_par =  dividend_int;
   end                                                                                    


reg_rst_stall # (
		 .stall_mode(stall_mode),
		 .rst_mode(rst_mode),
		 .data_wid(a_width + b_width+1)
		)
	     si(
		  .rst_n(rst_n),
		  .clk(clk),
		  .din({quot_par,rem_par}),
		  .en(en),
		  .dout({dividend_r,sum_r})
		);


reg_rst_stall # (
		 .stall_mode(stall_mode),
		 .rst_mode(rst_mode),
		 .data_wid(1)
		)
	     di(
		  .rst_n(rst_n),
		  .clk(clk),
		  .din(div_by_0),
		  .en(en),
		  .dout(div_by_0_r)
		);

endmodule
