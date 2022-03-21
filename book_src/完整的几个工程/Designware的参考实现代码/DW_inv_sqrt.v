 
// Description : Performs the inverse square root of the given input number
//-------------------------------------------------------------------------------------------------
`timescale 1ns / 10ps
module DW_inv_sqrt #(
											parameter	a_width 			= 10,
																prec_control	=	0
										)
									(
										input				[a_width-1:0]	a,
										output	reg	[a_width-1:0]	b,
										output										t
									) /* synthesis syn_builtin_du = "weak" */;


localparam width 			= 2*a_width;								
localparam width_opt	=	width - prec_control;
localparam int_width 	= width + width % 2;

wire 	[2*a_width-1:0] 						ex_ip;

reg 	[width_opt:0] 							quo;
reg		[width_opt + 2 -1:0] 				init_val;
reg 	[width_opt + 2 -1:0] 				sub_val;
reg 	[width_opt + 2 -1:0] 				add_val;
reg		[width_opt + 2 -1:0] 				sum;
reg		[int_width-1:0]							num;
reg		[width_opt + int_width-1:0] sh_input;
reg																addnsub;
reg	 	[2*a_width-1:0] 						sq_rt;

reg 	[3*a_width-1:0] 						numer;
reg		[a_width-1:0]								b_int;

integer i;

// Extend the input to double the width
assign ex_ip = {a,{a_width{1'b0}}};
assign t = 1'b1;
always @ *
	begin
		if(width % 2)
			num = {1'b0,ex_ip};
		else
			num = ex_ip;
		
		init_val 			= {{width_opt{1'b0}},2'b01};
		sub_val	 			= ~init_val + 1;
		sh_input		 	= {{(width_opt){1'b0}},num};
		addnsub 			= 0;
		quo						=	0;

		for(i=0;i<width_opt;i=i+1)
			begin	
				add_val = sh_input[width_opt + int_width -1:int_width-2];
				sum = add_val + sub_val;
				if(sum[width_opt + 2 -1])   // Remainder is negative so on the next iteration perform addition
					begin
						addnsub = 1;
						quo[0] = 0;								// set the quo lsb bit to 0
					end
				else
					begin
						addnsub = 0;
						quo[0] = 1;
					end

				sh_input[width_opt + int_width -1:int_width-2] = sum;
				sub_val[width_opt +2 -1:2] = quo[width_opt-1:0];
				quo 		= quo << 1;

				if(addnsub)
					begin
						sub_val[1] = 1'b1;
						sub_val[0] = 1'b1;
						sub_val = sub_val;
					end
				else
					begin
						sub_val[1] = 1'b0;
						sub_val[0] = 1'b1;
						sub_val = ~sub_val + 1;
					end
				sh_input = sh_input << 2;
			end
			sq_rt = 0;
			sq_rt[width-1:width-width_opt] = quo[width_opt:1];
			
			numer = {1'b1,{(3*a_width-1){1'b0}}};
			b_int = (numer/sq_rt);
			b 		=	(b_int[a_width-1] == 0 || (~a[a_width-1] & ~a[a_width-2]) ) ? {a_width{1'b1}} : b_int;
	end
endmodule
