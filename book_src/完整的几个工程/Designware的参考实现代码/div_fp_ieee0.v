
//-------------------------------------------------------------------------------------------------
//
// Title       : div_fp_ieee0
// Design      : Floating point divider
//
//-------------------------------------------------------------------------------------------------
// Description : DW_fp_div is a floating point divider that divides two floating point operands:
// a by b to produce a floating point quotient, z.
// 
// The input rnd is an optional 3-bit rounding mode and the output status is an 8-bit optional status 
// flags.
// Note : This module is supported only for Single & Double Precision
//-------------------------------------------------------------------------------------------------			
`timescale 1ps / 1ps
module div_fp_ieee0 (	
					 a,      //Dividend
    				 b,      //Divisor
                     rnd,    //Optional, Rounding mode
                     z,      //Quotient of a/b
                     status  //Optional, Status flags
                    )/* synthesis syn_builtin_du = "weak" */;												 
			
		parameter sig_width = 23; //Word length of fraction field of floating point numbers a, b, and z
		parameter exp_width = 8;  //Word length of biased exponent of floating point numbers a, b,	and z
		
		parameter	faithful_round = 0;

		//Internal parameters
		localparam isize = sig_width+exp_width+1; //Word length a, b and z
		localparam bias_value = ( 1 << (exp_width-1) ) - 1;
		localparam w_isize = clogb2(isize)-1'b1;
		
	//Input/Output declaration	
	   input  [isize-1:0]        a;
	   input  [isize-1:0]        b;
	   input  [2:0]              rnd;
	   output [isize-1:0]        z;
	   output [7:0]              status;
	
    //Internal signal declaration
	   wire [7:0]                 status;                                                       
	   wire                 	  zero;                                                         
	   wire                 	  infinity;                                                     
	   wire                 	  invalid;                                                      
	   wire                 	  tiny;                                                         
	   wire                 	  huge;                                                         
	   wire                 	  inexact; 
	   wire                       div_by_zero;
	   wire                       chk_eaz;
	   wire                       chk_ebz;
	   wire                       chk_ea1;
	   wire                       chk_eb1;
	   wire                       man_az;
	   wire                       man_bz;
	   wire                       nan_a;
	   wire                       nan_b;
	   wire                       inf_a;
	   wire                       inf_b;
	   wire [exp_width:0]         s1;
	   wire [exp_width:0]         bias_add_exp;	
	   wire [sig_width:0]         man_a;
	   wire [sig_width:0]         man_b;
	   wire [sig_width+sig_width+2:0]         quot;	
	   wire [sig_width:0]         rem;
	   wire [w_isize-1:0]         result;
	   wire [w_isize-1:0]         lzd_cnt;
	   wire [sig_width+2:0]       lsh_out;	   
	   wire [exp_width-1:0]       res_exp; 
	   wire                       res_msb;
	   wire [sig_width-1:0]       res_man;
	   wire                       res_sign;
	   wire                       res_man_z;  
	   wire [isize-1:0]           res;
	   wire [isize-1:0]           mod_res;
	   reg  [isize-1:0]           rounded;
	   reg  [isize-1:0]           z;
	   
	   
	/**************************************
     Steps to implement div:
     1. subtract exp_a - exp_b
     2. add the bias  
	 3. divide man_a/man_b
     4. normalize the result
    ***************************************/ 
	//Check the operands for normalization
		assign chk_eaz = a[isize-2:sig_width] == 0;
		assign chk_ebz = b[isize-2:sig_width] == 0; 
		assign chk_ea1 = a[isize-2:sig_width] == {exp_width{1'b1}};
		assign chk_eb1 = b[isize-2:sig_width] == {exp_width{1'b1}};
		assign nan_a = chk_ea1;//a[isize-2:sig_width] == {exp_width{1'b1}} && !man_az;
		assign nan_b = chk_eb1;//b[isize-2:sig_width] == {exp_width{1'b1}} && !man_bz;
		assign inf_a = chk_ea1;//a[isize-2:sig_width] == {exp_width{1'b1}} && man_az;
		assign inf_b = chk_eb1;//b[isize-2:sig_width] == {exp_width{1'b1}} && man_bz;

		/**** debugging ----- delete **/
		wire [exp_width-1:0] exp_a = a[isize-2:sig_width];
		wire [exp_width-1:0] exp_b = b[isize-2:sig_width];
		/******************/
	//Subtract the exponents			  
	assign s1 = a[isize-2:sig_width] - b[isize-2:sig_width];
    assign bias_add_exp = s1 + bias_value;
		
	//Divide the mantissas - add hidden bit first
	assign man_a = chk_eaz ? {a[sig_width-1:0],1'b0} : {1'b1,a[sig_width-1:0]};
	assign man_b = chk_ebz ? {b[sig_width-1:0],1'b0} : {1'b1,b[sig_width-1:0]};
    /************
	* Since the MSB is always 1 in divisor and dividend, the quotient is always 1.
	* In order to have accuracy, add zeros to the LSB and remove them while assigning 	
	* it to quotient.
	* Ex. 1001/1000 = 0001
	* 10010000/1000 = 00010010
	* 100100000/1000 = 000100110
	* while assigning remove 3MSB's and take only 4bits
	*************/
	assign quot = {man_a, {sig_width+2{1'b0}}} / man_b; 
	assign rem = {man_a, {sig_width+2{1'b0}}} % man_b;
	
	//send quot to function to find the first '1'
	assign result = lzd(quot[sig_width+2:0]);
    assign lzd_cnt = result;
	
	//lzd: leading zero detector - Find the first '1' by shifting input to left 
	   function [w_isize-1:0] lzd; 
	   input [sig_width+2:0]     inp_a;
	   reg                     flag;
	   reg   [w_isize-1:0]     sh_cnt; 
	   integer                 i;   
	   begin 
	           sh_cnt = 1;
			   flag = 1'b1; 
			   for (i=sig_width+2; i>=0; i=i-1)	
				   if ( inp_a[i] && flag )
					   begin 
						   flag = 0;
						   sh_cnt = sig_width+2-i;
					   end	
			   lzd = sh_cnt;
	   end 		
	   endfunction 	   
	   
	   //Calculate the result
	   assign lsh_out = quot[sig_width+2:0] << lzd_cnt;//quot[25:0] << lzd_cnt; 
	   assign res_man = lsh_out[sig_width+1:2];
	   assign {res_msb,res_exp} = bias_add_exp - lzd_cnt;
	   assign res_sign = a[isize-1] ^ b[isize-1];
	   assign res_man_z = res_man == 0;	 
	   assign res = {res_sign, res_exp, res_man};
	   assign mod_res = res + 1'b1;
	   
	   always @(*)
		   case ( rnd )
		   3'b000: 	/* 1.decide which is the last digit to keep. 
		               2.Increase it by 1 if the next digit is '1'
			   		   3.leave it as it is if the next digit is '0'
					   4.round up or down to the nearest even digit if the next digit is a '1' 
						 followed (if followed at all) only by zeroes. That is, increase the 
						 rounded digit if it is currently odd; leave it if it is already even. 
		  			*/			           
		            /* The bit new_a[isize-sig_width-1] is redundant in (new_a[isize-sig_width-2:0] == {(isize-sig_width-1){1'b0}})
					comparison and hence not considered. Also, remember we are choosing pack anyway if all the discarded bits are 0's.
					assign z = zero ? 0 : (inexact ?  rounded : new_a);	
					last digit to keep|I digit to discard, II digit to discard...
					0|100...0
					0|0xx...x
					1|0xx...x
					choose new_a
					0|1xx...x
					1|1xx...x
					choose mod_a
					*/
					if (!lsh_out[1])
						rounded = res;
					else 
						rounded = mod_res;					
			   3'b001:  rounded = res;
			   3'b010:  rounded = res_sign ? res : mod_res;
			   3'b011:  rounded = res_sign ? mod_res : res;
			   3'b100:  if (lsh_out[1])
						   rounded = mod_res;
					   else	
						   rounded = res;
			   3'b101:  rounded = mod_res;		   
			   3'b110:  rounded = mod_res; 
			   3'b111:  rounded = mod_res; 
		   endcase								  		   						   

	   always @(*)
			 if (invalid)
			   z = {1'b0, {exp_width{1'b1}}, {sig_width{1'b0}}};
			 else if (infinity || div_by_zero)
				begin
			   	 z = {res_sign, {exp_width{1'b1}}, {sig_width{1'b0}}};
				end
		   else if (huge) 
			   case (rnd )
				   3'b001: z = {res_sign, {exp_width-1{1'b1}}, 1'b0, {sig_width{1'b1}}};//(rnd == 1 || (rnd == 2 && res_sign) || (rnd == 3 && !res_sign) ) ? {res_sign, {exp_width-1{1'b1}}, 1'b0, {sig_width{1'b1}}} : {res_sign, {exp_width-1{1'b1}}, 1'b1, {sig_width{1'b0}}};  
				   3'b010: z = res_sign ? {1'b1, {exp_width-1{1'b1}}, 1'b0, {sig_width{1'b1}}} : {1'b0, {isize-1{1'b1}}};
				   3'b011: z = res_sign ? {isize{1'b1}} : {1'b0, {exp_width-1{1'b1}}, 1'b0, {sig_width{1'b1}}};
				   default: z = {res_sign, {isize-1{1'b1}}};
			   endcase			   
		   else	if (tiny)
			   begin
				   case (rnd)
					   3'b010: z = res_sign ? {1'b1, {isize-1{1'b0}}} : {1'b0, {exp_width-1{1'b0}}, 1'b1, {sig_width{1'b0}}};
                       3'b011: z = res_sign ? {1'b1, {exp_width-1{1'b0}}, 1'b1, {sig_width{1'b0}}} : {1'b0, {isize-1{1'b0}}};					   
					   3'b101: z = res_sign ? {1'b1, {exp_width-1{1'b0}}, 1'b1, {sig_width{1'b0}}} : {1'b0, {exp_width-1{1'b0}}, 1'b1, {sig_width{1'b0}}};
					   default: z = {res_sign, {isize-1{1'b0}}};
				   endcase	
			   end			   
		   else	if (chk_eaz || nan_b || inf_b)
			   z = {res_sign, {isize-1{1'b0}}};
		   else			   			   
            z = inexact ? rounded :{res_sign, res_exp, res_man};				 
	   
	   assign zero = !invalid && (( chk_eaz && !chk_ebz) || chk_eb1 || (tiny && rnd!=2 && rnd !=3 && rnd != 5) || (tiny && rnd == 2 && res_sign) || (tiny && rnd == 3 && !res_sign));	   
	   assign infinity = !invalid && ( chk_ebz || chk_ea1 || (huge && rnd!=1 && rnd != 2 && rnd !=3 ) || (huge && rnd == 2 && !res_sign) || (huge && rnd == 3 && res_sign)); 	   
	   assign invalid = (chk_eaz && chk_ebz) || (chk_ea1 && chk_eb1);
	   assign tiny = !nan_b && !chk_eaz && ((s1[exp_width] && bias_add_exp[exp_width]) || (bias_add_exp == 0 ) || (!res_msb && res_exp == 0)) & ~huge ;
	   assign huge = !invalid && ((!s1[exp_width] && bias_add_exp[exp_width] && !chk_ea1 && !chk_ebz) || ( bias_add_exp == {exp_width{1'b1}} && res_exp == {exp_width{1'b1}}));
         //whenever tiny or huge is set due to proper inputs(exclude exceptions), inexact = 1
	   assign inexact = (!invalid && (rem!=0 || tiny || huge) && ~(chk_ea1 || chk_eb1) && ~(chk_ebz || chk_eaz)) & ~div_by_zero ;   
	   assign div_by_zero = chk_ebz & ~invalid;
		 assign huge_out = huge & ~(chk_ebz || chk_ea1);

		 assign tiny_out = tiny & ~div_by_zero;
		 assign zero_out = zero & ~div_by_zero;
     assign status = {div_by_zero, 1'b0, inexact, huge_out, tiny_out , invalid, infinity, zero_out};
	   
	   //function to obtain bit width
	   function integer clogb2 (input integer depth);
	   begin
		   for(clogb2=0; depth>0; clogb2=clogb2+1)
			   depth = depth >> 1;
	   end
       endfunction
	
endmodule
