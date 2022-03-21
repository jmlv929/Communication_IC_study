	
//-------------------------------------------------------------------------------------------------
//
// Title       : DW_fp_mult
// Design      : Floating point multiplier
//
//-------------------------------------------------------------------------------------------------
// Description : DW_fp_mult is a floating point multiplier that multiplies two floating point values,
// a and b, to produce a floating point sum, z.
// 
// The input rnd is an optional 3-bit rounding mode and the output status is an 8-bit optional status 
// flags.
// Note : This module is supported only for Single & Double Precision
//-------------------------------------------------------------------------------------------------			
`timescale 1ps / 1ps
module fp_mult_ieee1 (	
					 a,      //Multiplier
    				 b,      //Multiplicand
                     rnd,    //optional, Rounding mode
                     z,      //Product of a X b
                     status  //optional, Status flags
                    )/* synthesis syn_builtin_du = "weak" */;												 
			
		parameter sig_width = 23; //Word length of fraction field of floating point numbers a, b, and z
		parameter exp_width = 8;  //Word length of biased exponent of floating point numbers a, b,	and z

		//Internal parameters
		parameter isize = sig_width+exp_width+1; //Word length a and b
		parameter bias_value = ( 1 << (exp_width-1) ) - 1;
		parameter w_isize = clogb2(isize)-1'b1;
		
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
	   wire                       chk_a;
	   wire                       chk_b; 
	   wire                       man_az;
	   wire                       man_bz;
	   wire                       a_z;
	   wire                       b_z;
	   wire                       nan_a;
	   wire                       nan_b;
	   wire                       inf_a;
	   wire                       inf_b;
	   wire [exp_width:0]         s1;
	   wire [exp_width:0]         bias_add_exp;	
	   wire [exp_width:0]         temp_exp;	
//	   wire [exp_width:0]         rsh_cnt;	
	   wire [exp_width-1:0]       rsh_cnt;	
	   wire [w_isize-1:0]         sat_rsh_cnt;	
	   wire [sig_width:0]         man_a;
	   wire [sig_width:0]         man_b;
	   wire [(2*sig_width)+1:0]   prod; //width = (sig_width+1) * 2--take hidden bits into consideration
	   wire	  				      cmp_half;
	   wire [w_isize-1:0]         result;
	   wire [w_isize-1:0]         lzd_cnt;
	   wire [(2*sig_width)+1:0]   lsh_out; 
	   wire [(2*sig_width)+1:0]   temp;		 
	   wire [(2*sig_width)+1:0]   rsh_in;
	   wire [(2*sig_width)+1:0]   temp_rsh;
	   wire [sig_width-1:0]       rsh_out;
	   wire [exp_width-1:0]       res_exp;
	   wire [sig_width-1:0]       res_man;
	   wire                       rsh_sticky;
	   wire                       lsh_sticky;
	   wire                       res_sign;
	   wire                       res_man_z;
	   wire                       carry_exp;
	   wire [isize-1:0]           res;
	   wire [isize-1:0]           mod_res;
	   reg  [isize-1:0]           rounded;
	   reg  [isize-1:0]           z;
	   
	   
	/**************************************
     Steps to implement mult:
     1. Check the operands for normalization
     2. If normalized, subtract the bias  
	 3.	add the exponents and bias it
	 4. multiply mantissas
     5. normalize the result
    ***************************************/ 
	//Check the operands for normalization
		assign chk_a = a[isize-2:sig_width] == 0;
		assign chk_b = b[isize-2:sig_width] == 0; 
		assign man_az = a[sig_width-1:0] == 0;
		assign man_bz = b[sig_width-1:0] == 0;
		assign nan_a = a[isize-2:sig_width] == {exp_width{1'b1}} && !man_az;
		assign nan_b = b[isize-2:sig_width] == {exp_width{1'b1}} && !man_bz;
		assign inf_a = a[isize-2:sig_width] == {exp_width{1'b1}} && man_az;
		assign inf_b = b[isize-2:sig_width] == {exp_width{1'b1}} && man_bz;
		assign a_z = chk_a && man_az;
		assign b_z = chk_b && man_bz;
		
	//Add the exponents	-- check whether the biased exp can be used for 
	assign s1 = a[isize-2:sig_width] + b[isize-2:sig_width];
    assign bias_add_exp = s1 - bias_value;
	assign rsh_cnt = carry_exp ? ~temp_exp[exp_width-1:0] + 1'b1 : ~bias_add_exp + 1'b1;//bias_value - s1;	
	assign sat_rsh_cnt = rsh_cnt > (sig_width+1) ? (sig_width+2) : rsh_cnt;
		
	//Multiply mantissas - add hidden bit first
	assign man_a = chk_a ? {a[sig_width-1:0],1'b0} : {1'b1,a[sig_width-1:0]};
	assign man_b = chk_b ? {b[sig_width-1:0],1'b0} : {1'b1,b[sig_width-1:0]};
    assign prod = man_a * man_b;
	//send only half input to function to find the first '1'
    assign cmp_half = prod[(2*sig_width)+1:sig_width+1] == 0;
	assign result = lzd(prod[(2*sig_width)+1:sig_width+1]);
	//If there is no '1' in the MSB half then the mantissa will be all 0's --assign max. value to lzd_cnt
    assign lzd_cnt = cmp_half ? {w_isize{1'b1}} : result;//denormals ????
	
	//lzd: leading zero detector - Find the first '1' by shifting input to left 
	   function [w_isize-1:0] lzd; 
	   input [sig_width:0]     inp_a;
	   reg                     flag;
	   reg   [w_isize-1:0]     sh_cnt; 
	   integer                 i;   
	   begin 
	           sh_cnt = 2;
			   flag = 1'b1; 
			   for (i=sig_width; i>=0; i=i-1)	
				   if ( inp_a[i] && flag )
					   begin 
						   flag = 0;
						   sh_cnt = sig_width-i;
					   end	
			   lzd = sh_cnt;
	   end 		
	   endfunction 	   
	   
	   //Calculate the result
	   assign lsh_out = prod << lzd_cnt; 
	   assign temp = {prod[(2*sig_width)+1:sig_width], {sig_width{1'b0}}}; //extra bit for rounding	
	   assign rsh_in = carry_exp ? {lsh_out[(2*sig_width)+1:sig_width], {sig_width{1'b0}}} : temp; 
	   assign temp_rsh = rsh_in >> sat_rsh_cnt;
	   assign rsh_out = temp_rsh[(sig_width*2)+1:sig_width+1];
	   assign res_man = tiny ? rsh_out : lsh_out[sig_width*2:sig_width+1];	
	   assign {carry_exp,temp_exp} = bias_add_exp - lzd_cnt;
	   assign res_exp = (a_z || b_z || tiny || carry_exp) ? 0 : temp_exp[exp_width-1:0]+1'b1;
	   assign res_sign = a[isize-1] ^ b[isize-1];
	   assign res_man_z = z[sig_width-1:0] == 0;	 
	   assign lsh_sticky = |lsh_out[sig_width-1:0];
	   assign rsh_sticky = |temp_rsh[sig_width:0] || |prod[sig_width:0];
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
					if (tiny)
						begin
							if ((!temp_rsh[sig_width+1] && temp_rsh[sig_width] && !rsh_sticky ) || (!temp_rsh[sig_width]))
								rounded = res;
							else 
								rounded = mod_res;
						end
					else
						begin 
							if ((!lsh_out[sig_width+1] && lsh_out[sig_width] && !lsh_sticky ) || (!lsh_out[sig_width]))
								rounded = res;
							else 
								rounded = mod_res;					
						end	
					
			   3'b001:  rounded = res;
			   3'b010:  rounded = res_sign ? res : mod_res;
			   3'b011:  rounded = res_sign ? mod_res : res;
			   3'b100:  if (tiny)
				   begin 
					   if (	temp_rsh[sig_width])
						   rounded = mod_res;
					   else	
						   rounded = res;
					end
					else
						begin
							if (lsh_out[sig_width])  //if G is 1, choose up.
								rounded = mod_res;
							else 
								rounded = res;
						end		
			   3'b101:  rounded = mod_res;		   
			   3'b110:  rounded = mod_res; 
			   3'b111:  rounded = mod_res; 
		   endcase								  		   						   

	   always @(*)
		   if (invalid)
			   z = {1'b0, {exp_width{1'b1}}, {sig_width-1{1'b0}}, 1'b1};
		   else if ((inf_a && (!chk_b || !man_bz)) || (inf_b && (!chk_a || !man_az))) //spl. case inf * !0
			   z = {res_sign, {exp_width{1'b1}}, {sig_width{1'b0}}};
		   else if (huge)
			   z = (rnd == 1 || (rnd == 2 && res_sign) || (rnd == 3 && !res_sign) ) ? {res_sign, {exp_width-1{1'b1}}, 1'b0, {sig_width{1'b1}}} : {res_sign, {exp_width-1{1'b1}}, 1'b1, {sig_width{1'b0}}};  
		   else	if (chk_a && chk_b)// && rmz)
			   z = {res_sign, {isize-1{1'b0}}};
		   else	   
               z = inexact ? rounded :{res_sign, res_exp, res_man};				 
	   
	   assign zero = !invalid && ((z[isize-2:sig_width] == 0 && res_man_z) || (a_z || b_z));	   
	   assign infinity = !invalid && (z[isize-2:sig_width] == {exp_width{1'b1}} && res_man_z) || (huge && rnd!=1 && rnd != 2 && rnd !=3 ) || (huge && rnd == 2 && !res_sign) || (huge && rnd == 3 && res_sign);
	   assign invalid = nan_a || nan_b || (inf_a && chk_b && man_bz) || (inf_b && chk_a && man_az); 
	   assign tiny = ~(a_z || b_z) && ((!s1[exp_width] && bias_add_exp[exp_width] ) || carry_exp || (bias_add_exp - (lzd_cnt - 1) == 0));
//	   assign huge = !invalid && ~(inf_a || inf_b) && (((s1[exp_width] && bias_add_exp[exp_width]) || ( bias_add_exp == {exp_width{1'b1}})) || (res_exp == {exp_width{1'b1}} && !rmz));
	   assign huge = !invalid && ~(inf_a || inf_b) && (((s1[exp_width] && bias_add_exp[exp_width]) || ( bias_add_exp == {exp_width{1'b1}})) || (res_exp == {exp_width{1'b1}}));
	   assign inexact = !invalid && (tiny ? rsh_sticky : |lsh_out[sig_width:0]) || huge;
       assign status = {2'b0, inexact, huge, tiny, invalid, infinity, zero};
	   
	   //function to obtain bit width
	   function integer clogb2 (input integer depth);
	   begin
		   for(clogb2=0; depth>0; clogb2=clogb2+1)
			   depth = depth >> 1;
	   end
       endfunction
	
endmodule
