

//-------------------------------------------------------------------------------------------------
//
// Title       : addsub_fp_ieee0
// Design      : Integer to Floating Point Converter
//
//-------------------------------------------------------------------------------------------------
// Description : DW_fp_addsub is a floating point component that is capable of adding or subtracting 
// two floating point values, a and b, to produce a floating point result z. The control over the
// arithmetic operation is done through the input op.
// 
// The input rnd is an optional 3-bit rounding mode and the output status is an 8-bit optional status 
// flags. The functionality of this module is IEEE compliant.
// Note : This module is supported only for Single & Double Precision
//-------------------------------------------------------------------------------------------------			
`timescale 1ps / 1ps
module addsub_fp_ieee0 (	
					 a,      //Input data
    				 b,      //Input data
                     op,     //Defines the operation: 0- addition, 1-subtraction
                     z,      //a op b
                     status, //optional, Status flags
                     rnd     //optional, Rounding mode
                    )/* synthesis syn_builtin_du = "weak" */;												 
			
		parameter sig_width = 23; //Word length of fraction field of floating point numbers a, b, and z
		parameter exp_width = 8;  //Word length of biased exponent of floating point numbers a, b,	and z

		//Internal parameters
		parameter isize = sig_width+exp_width+1; //Word length a and b
		parameter bias_value = ( 1 << (exp_width-1) ) - 1;
		parameter w_isize = clogb2(isize)-1'b1;
		
	//Input/Output declaration	
	   input  [isize-1:0]             a;
	   input  [isize-1:0]             b;
	   input                          op;
	   input  [2:0]                   rnd;
	   output [sig_width+exp_width:0] z;
	   output [7:0]                   status;
	
    //Internal signal declaration
	   wire [7:0]                 status;                                                       
	   wire                 	  inexact;                                                      
	   wire                 	  infinity;                                                     
	   wire                 	  huge;                                                         
	   wire                 	  tiny;                                                         
	   wire                 	  invalid;                                                      
	   wire                 	  zero;   
	   wire [exp_width-1:0] 	  sh_val;                                                       
	   wire [w_isize-1:0] 	      sat_sh_val;                                                       
	   wire [sig_width+4:0] 	  add_man;//1(hidden)+sig_width+3(GRS)+1(for carry out)         
	   wire [w_isize-1:0]   	  lzd_cnt;                                                      
	   wire [w_isize-1:0]   	  call_lzd;                                                      
	   wire [sig_width+3:0] 	  lsh_out;                                                      
	   wire [isize-1:0]     	  larger;                                                       
	   wire [isize-1:0]     	  smaller;                                                      
	   wire                 	  larger_sign;                                                  
	   wire                 	  smaller_sign;   
	   wire                 	  a_sign;                                                  
	   wire                 	  b_sign;   
	   wire                       sticky_bit;
	   wire                       denorm_l;
	   wire                       denorm_s;
	   wire [sig_width+2:0] 	  rsh_out; //1'b1+guard and round bits                          
	   wire [sig_width+3:0] 	  man_larger;                                                   
	   wire	[sig_width+3:0] 	  man_smaller;                                                  
	   reg  [isize-1:0]     	  rounded;                                                      
	   wire [sig_width-1:0] 	  res_man;                                                      
	   wire [exp_width-1:0] 	  res_exp;  
	   wire                       res_sign;
	   wire [isize-1:0]     	  res;                                                          
	   wire [isize-1:0]     	  mod_res;                                                      
	   reg  [isize-1:0]     	  z;                                                            
	   wire                       res_man_z; 
	   wire                       res_exp_1; 
	   wire                       comp;
	   wire                       LT;
	   wire                       EQ;
	   wire                       lar_hb;
	   wire                       sma_hb;
	   wire [(sig_width*2)+1:0]   rsh_small;
	   wire [(sig_width*2)+1:0]   temp;
	   wire                       round;
	   wire                       guard;
	   wire                       msb_in_lzd;
	   wire                       chk_el1;
	   wire                       chk_es1;
	   wire                       man_lz;
	   wire                       man_sz;
	   wire                       nan_l;
	   wire                       nan_s;
	   wire                       inf_l;
	   wire                       inf_s;
	   wire                       sticky_rne; 
	   wire                       cmp;
	   
    /**************************************
     Steps to implement adder:
     1. Align radix points: shift the smaller no. to right ( beware of hidden '1')
     2. Add (beware of hidden '1' in the bigger no.)
     3. normalize the result
    ***************************************/
	 //Update the status flags - HugeInt and PassA/Divide by zero are not affected by this component
     assign status = {2'b0, inexact, huge, tiny, invalid, infinity, zero};
	 assign inexact =  !invalid && ~(chk_el1 || chk_es1 ) && (!denorm_s && (guard || round || sticky_bit || huge || tiny)); 
	 assign huge = !invalid && res_exp == {exp_width{1'b1}} && res_man != 0 && !(chk_el1 || chk_es1 );
	 assign tiny = !invalid && !EQ && (res_exp == 0 && !denorm_s && !cmp) ;
	 assign invalid = (chk_el1 && chk_es1 && comp);// only subtraction of inf's causes invalid
	 assign infinity = (chk_el1 || chk_es1 ) || (huge && rnd!=1 && rnd != 2 && rnd !=3 ) || (huge && rnd == 2 && !res_sign) || (huge && rnd == 3 && res_sign);
     assign zero = z[isize-2:0] == 0;
	 assign res_man_z = z[sig_width-1:0] == 0;
	 assign res_exp_1 = z[isize-2:sig_width] == {exp_width{1'b1}}; 
	 
	 //comparator to compare exponents of a and b: 
	 assign LT = a[isize-2:0] < b[isize-2:0]; 
	 assign larger = LT ? b : a;	
	 assign smaller = LT ? a : b;	
	 assign larger_sign = larger[isize-1];
	 assign smaller_sign = smaller[isize-1];  
	 wire [exp_width-1:0] lar_exp = larger[isize-2:sig_width];
	 assign a_sign = a[isize-1];
	 assign b_sign = b[isize-1];
	 assign comp = op ? ~(larger_sign ^ smaller_sign) : (larger_sign ^ smaller_sign); 
	 assign denorm_l = larger[isize-2:sig_width] == 0;
	 assign denorm_s = smaller[isize-2:sig_width] == 0;
	 //Check the operands for NaNs and INFs 	
	 assign chk_el1 = larger[isize-2:sig_width] == {exp_width{1'b1}};	
	 assign chk_es1 = smaller[isize-2:sig_width] == {exp_width{1'b1}};
	 assign nan_l = chk_el1; 
	 assign nan_s = chk_es1; 
	 assign inf_l = chk_el1; 
	 assign inf_s = chk_es1;
	 assign sh_val = larger[isize-2:sig_width] - smaller[isize-2:sig_width];
// wire huge_shft = |(sh_val[exp_width-1:w_isize]);
	 wire huge_shft = |(sh_val[(exp_width-1 > w_isize ? exp_width - 1 : w_isize) : (w_isize < exp_width-1 ? w_isize : exp_width-1)]);
	 assign sat_sh_val = huge_shft ? {w_isize{1'b1}} : sh_val[w_isize-1:0];	 

	 //decide the hidden bit(hb) to consider during addition and shift: man =0, then LSB=0 else MSB = 1 
	 assign lar_hb = ~denorm_l;
	 assign sma_hb = ~denorm_s;
	 
	 //implement rsh to align exponents
	 assign rsh_small = sma_hb ? {1'b1, smaller[sig_width-1:0], {sig_width+1{1'b0}}} : {smaller[sig_width-1:0],1'b0, {sig_width+1{1'b0}}};
	 assign temp  = rsh_small >> sat_sh_val;
	 assign rsh_out = temp[(sig_width*2)+1:sig_width-1];//taken G(sig_width) and R(sig_width-1)
	 assign sticky_bit = (|temp[sig_width-2:0]);
	 
	 assign man_larger = lar_hb ? {1'b1, larger[sig_width-1:0], 3'b0} : {larger[sig_width-1:0], 4'b0};
	 assign man_smaller =  comp ? ~({rsh_out,sticky_bit}) + 1'b1 : {rsh_out,sticky_bit};//guard,round,sticky	   
	 assign add_man = man_larger + man_smaller;	
	 assign msb_in_lzd = (comp ^ add_man[sig_width+4]);//to take care of 2's complement addition carry
	 assign call_lzd = lzd({msb_in_lzd, add_man[sig_width+3:1]});//discard LSB which is sticky bit 
 	 assign EQ = sat_sh_val == 0 && call_lzd == {w_isize{1'b1}}; 

	 assign cmp = call_lzd < lar_exp;
     assign lzd_cnt = call_lzd;

	   //lzd: leading zero detector - Find the first '1' by shifting input to left 
	   function [w_isize-1:0] lzd; 
	   input [sig_width+3:0]   inp_a;
	   reg                     flag;
	   reg   [w_isize-1:0]     sh_cnt; 
	   integer                 i;   
	   begin 
	           sh_cnt = {w_isize{1'b1}};
			   flag = 1'b1; 
			   for (i=sig_width+3; i>=0; i=i-1)	
				   if ( inp_a[i] && flag )
					   begin 
						   flag = 0;
						   sh_cnt = (sig_width+3)-i;
					   end	
			   lzd = sh_cnt;
	   end 		
	   endfunction 	   
	 assign lsh_out = {msb_in_lzd,add_man[sig_width+3:1]} << (lzd_cnt);
	 //When both denormals are treated as 0 and hence the resultant mantissa = lar_man
     wire [exp_width-1:0] temp_exp = larger[isize-2:sig_width] - (call_lzd - 1); 
	 assign res_exp = (!cmp && temp_exp[exp_width-1]) ?  0 : temp_exp; 
     assign res_man = lsh_out[sig_width+2:3];//leave the hidden '1' at MSB	
	 assign res_sign = op ? ( (a_sign == b_sign && b == larger) ? ~b_sign : a_sign ) : larger_sign;
	 assign res = {res_sign, res_exp, res_man};		 
	 assign mod_res = res + 1'b1;
	 assign guard = lsh_out[2];																						   
	 assign round = lsh_out[1] | lsh_out[0];
	 assign sticky_rne = round | sticky_bit;
	 
	   //The output is affected by rounding, if the discarded value > 0
	   always @(*)//(rnd or res or mod_res or res_sign or sticky_bit or lsh_out or add_man)
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
					   if ((!lsh_out[3] && lsh_out[2] && !sticky_rne ) || (!lsh_out[2]))// && !comp))// || (!lsh_out[1] && (huge_shft ^ sticky_bit)))
						   rounded = res;
					   else 
						   rounded = mod_res;
			   3'b001:  rounded = res;
			   3'b010:  rounded = res_sign ? res : mod_res;
			   3'b011:  rounded = res_sign ? mod_res : res;
			   3'b100:  if (lsh_out[2])  //if G is 1, choose up.
						   rounded = mod_res;
					   else 
						   rounded = res;
			   3'b101:  rounded = mod_res;		   
			   3'b110:  rounded = mod_res; 
			   3'b111:  rounded = mod_res; 
		   endcase								  		   						   

	 	//Update the output, z 
		always @(*)
			if ( infinity )
				z = invalid ? {1'b0, {exp_width{1'b1}}, {sig_width{1'b0}}} : {res_sign, {exp_width{1'b1}}, {sig_width{1'b0}}};
	        else if ( huge ) 
			   z = (rnd == 1 || (rnd == 2 && res_sign) || (rnd == 3 && !res_sign) ) ? {res_sign, {exp_width-1{1'b1}}, 1'b0, {sig_width{1'b1}}} : {res_sign, {exp_width-1{1'b1}}, 1'b1, {sig_width{1'b0}}};  
			else if (denorm_s && denorm_l) //denormals are treated differently and hence output is different
				z = rnd == 3 ? {op ? ~(~a_sign && b_sign) : (a_sign || b_sign), {isize-1{1'b0}}} : {a_sign , {isize-1{1'b0}}};
            else if ( EQ )
				z = rnd == 3 ? {1'b1, {isize-1{1'b0}}} : {isize{1'b0}};
			else if (denorm_s) // 0 and -0 are not EQ and hence checking for denorm_l
//				z = op ? (denorm_l? {larger_sign, larger[isize-2:0]} : {res_sign,larger[isize-2:0]}): larger;		
				z = denorm_l ? (rnd == 3 && comp ? {1'b1, {isize-1{1'b0}}} : larger) : {res_sign,larger[isize-2:0]};		
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
			else	
	   	        z = (guard || round || sticky_bit) ? rounded : res;

	//function to obtain bit width
	   function integer clogb2 (input integer depth);
	   begin
		   for(clogb2=0; depth>0; clogb2=clogb2+1)
			   depth = depth >> 1;
	   end
       endfunction

	  /******** debugging ********/
	  wire [exp_width-1:0] sm_exp = smaller[isize-2:sig_width];	  
	  
	  endmodule 
