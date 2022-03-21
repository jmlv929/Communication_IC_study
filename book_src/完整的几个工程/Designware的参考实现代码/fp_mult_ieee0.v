
//-------------------------------------------------------------------------------------------------
//
// Title       : fp_mult_ieee0
// Design      : Floating point multiplier
//
//-------------------------------------------------------------------------------------------------
// Description : fp_mult_ieee0 is a floating point multiplier that multiplies two floating point values,
// a and b, to produce a floating point sum, z.
// 
// The input rnd is an optional 3-bit rounding mode and the output status is an 8-bit optional status 
// flags. This is not IEEE 754 compliant. Here denormals are treated as zeros and NANs as infinites.
//-------------------------------------------------------------------------------------------------			
`timescale 1ps / 1ps
module fp_mult_ieee0 (	
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
	   wire                       chk_eaz;
	   wire                       chk_ebz; 
	   wire                       chk_ea1;
	   wire                       chk_eb1; 
	   wire [exp_width:0]         s1;
	   wire [exp_width:0]         bias_add_exp;	
	   wire [exp_width:0]         temp_exp;	
	   wire [sig_width:0]         man_a;
	   wire [sig_width:0]         man_b;
	   wire [(2*sig_width)+1:0]   prod; //width = (sig_width+1) * 2--take hidden bits into consideration
	   wire	  				      cmp_half;
	   wire [w_isize-1:0]         result;
	   wire [w_isize-1:0]         lzd_cnt;
	   wire [(2*sig_width)+1:0]   lsh_out; 
	   wire [(2*sig_width)+1:0]   temp;		 
	   wire [exp_width-1:0]       res_exp;
	   wire [sig_width-1:0]       res_man;
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
		assign chk_eaz = a[isize-2:sig_width] == 0;
		assign chk_ebz = b[isize-2:sig_width] == 0; 
        //NAN and inf are treated as inf, hence checking for exp = all 1's if sufficient
        assign chk_ea1 = a[isize-2:sig_width] == {exp_width{1'b1}};
        assign chk_eb1 = b[isize-2:sig_width] == {exp_width{1'b1}};
		
	//Add the exponents	-- check whether the biased exp can be used for 
	assign s1 = a[isize-2:sig_width] + b[isize-2:sig_width];
    assign bias_add_exp = s1 - bias_value;
		
	//Multiply mantissas - add hidden bit first
	assign man_a = chk_eaz ? {a[sig_width-1:0],1'b0} : {1'b1,a[sig_width-1:0]};
	assign man_b = chk_ebz ? {b[sig_width-1:0],1'b0} : {1'b1,b[sig_width-1:0]};
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
	   assign res_man = lsh_out[sig_width*2:sig_width+1];	
	   assign res_exp = (chk_eaz || chk_ebz || tiny ) ? 0 : bias_add_exp - (lzd_cnt-1'b1);
	   assign res_sign = a[isize-1] ^ b[isize-1];
	   assign res_man_z = z[sig_width-1:0] == 0;	 
	   assign lsh_sticky = |lsh_out[sig_width-1:0];
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
					if ((!lsh_out[sig_width+1] && lsh_out[sig_width] && !lsh_sticky ) || (!lsh_out[sig_width]))
						rounded = res;
					else 
						rounded = mod_res;					
					
			   3'b001:  rounded = res;
			   3'b010:  rounded = res_sign ? res : mod_res;
			   3'b011:  rounded = res_sign ? mod_res : res;
			   3'b100:  if (lsh_out[sig_width])  //if G is 1, choose up.
				   rounded = mod_res;
			   else 
				   rounded = res;
			   3'b101:  rounded = mod_res;		   
			   3'b110:  rounded = mod_res; 
			   3'b111:  rounded = mod_res; 
		   endcase								  		   						   

	   always @(*)
		   if (infinity) 
			   z = {res_sign & !invalid , {exp_width{1'b1}}, {sig_width{1'b0}}};
		   else if (huge)
			   z = (rnd == 1 || (rnd == 2 && res_sign) || (rnd == 3 && !res_sign) ) ? {res_sign, {exp_width-1{1'b1}}, 1'b0, {sig_width{1'b1}}} : {res_sign, {exp_width-1{1'b1}}, 1'b1, {sig_width{1'b0}}};  
           else if ( tiny )
		       case ( rnd )
				   3'b010 : if (res_sign)
					   z = {1'b1, {isize-1{1'b0}}};
				   else 
					   z = {1'b0, {exp_width-1{1'b0}}, 1'b1, {sig_width{1'b0}}};
				   3'b011 : if (res_sign)
					   z = {1'b1, {exp_width-1{1'b0}}, 1'b1, {sig_width{1'b0}}};
				   else 
					   z = {1'b0, {isize-1{1'b0}}};
				   3'b101 : if (res_sign)
					   z = {1'b1, {exp_width-1{1'b0}}, 1'b1, {sig_width{1'b0}}};
				   else 
					   z = {1'b0, {exp_width-1{1'b0}}, 1'b1, {sig_width{1'b0}}};  
					default: z = {res_sign, {isize-1{1'b0}}}; 	 
				endcase	
			else if ( chk_eaz || chk_ebz )
				z = {res_sign, {isize-1{1'b0}}};	
		   else	   
               z = inexact ? rounded :{res_sign, res_exp, res_man};				 
	   
	   assign zero = !invalid && ((z[isize-2:sig_width] == 0) || (chk_eaz || chk_ebz));	   
//	   assign infinity = chk_ea1 || chk_eb1 || (huge && rnd!=1 && rnd != 2 && rnd !=3 ) || (huge && rnd == 2 && !res_sign) || (huge && rnd == 3 && res_sign);
	   assign infinity = chk_ea1 || chk_eb1 || (huge & ~(rnd == 1 || (rnd == 2 && res_sign) || (rnd == 3 && !res_sign) ) ) ; 
	   assign invalid =  (chk_ea1 && chk_ebz ) || (chk_eb1 && chk_eaz); 
	   assign tiny = ~(chk_eaz || chk_ebz) && ((!s1[exp_width] && bias_add_exp[exp_width] ) || (bias_add_exp - (lzd_cnt - 1) == 0));
	   assign huge = !invalid && ~( chk_ea1 || chk_eb1) && (((s1[exp_width] && bias_add_exp[exp_width]) || ( bias_add_exp == {exp_width{1'b1}})) || (res_exp == {exp_width{1'b1}}));
	   assign inexact = !invalid && ~(chk_ea1 || chk_eb1) && (~(chk_eaz || chk_ebz) && |lsh_out[sig_width:0] || huge || tiny);

		 assign inexact_out = (huge & ~(rnd == 1 || (rnd == 2 && res_sign) || (rnd == 3 && !res_sign) )) | inexact; 
		 assign infinity_out = ((z[isize-2:sig_width] == {exp_width{1'b1}})) | infinity;
		 assign huge_out = huge | (inexact_out & infinity_out);

		 assign tiny_sp = (bias_add_exp - (lzd_cnt -1) == 0) && (lzd_cnt == 1);


     assign status = {2'b0, inexact_out , huge_out   , tiny, invalid, infinity_out, zero};
	   
	   //function to obtain bit width
	   function integer clogb2 (input integer depth);
	   begin
		   for(clogb2=0; depth>0; clogb2=clogb2+1)
			   depth = depth >> 1;
	   end
       endfunction
	
endmodule
