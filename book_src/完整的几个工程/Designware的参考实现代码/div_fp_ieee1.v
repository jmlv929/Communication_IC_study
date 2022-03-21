

//-------------------------------------------------------------------------------------------------
//
// Title       : div_fp_ieee1
// Design      : Floating point divider
//
//-------------------------------------------------------------------------------------------------
// Description : DW_fp_div is a floating point divider that divides two floating point operands:
// a by b to produce a floating point quotient, z.
// 
// The input rnd is an optional 3-bit rounding mode and the output status is an 8-bit optional status 
// flags.
//-------------------------------------------------------------------------------------------------			
`timescale 1ps / 1ps
module div_fp_ieee1 (	
					 a,      //Dividend
    				 b,      //Divisor
                     rnd,    //Optional, Rounding mode
                     z,      //Quotient of a/b
                     status  //Optional, Status flags
                    )/* synthesis syn_builtin_du = "weak" */;												 
			
		parameter sig_width = 23; //Word length of fraction field of floating point numbers a, b, and z
		parameter exp_width = 8;  //Word length of biased exponent of floating point numbers a, b,	and z

		//Internal parameters
		parameter isize = sig_width+exp_width+1; //Word length a, b and z
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
	   wire                       div_by_zero;
	   wire                       chk_eaz;
	   wire                       chk_ebz;
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
	   wire [sig_width:0]         man_a;
	   wire [sig_width:0]         man_b;	 
       wire                       cp_man;
	   wire [sig_width+sig_width+2:0]         quot;	
	   wire [sig_width:0]         rem;
	   wire                       rem_z;
	   wire [w_isize-1:0]         result;
//	   wire [w_isize-1:0]         lzd_cnt;
	   wire [sig_width+2:0]       lsh_out;
	   wire [exp_width-1:0]       rsh_cnt;	
	   wire [w_isize-1:0]         rsh_cnt_sat;	
	   wire [sig_width+2:0]       rsh_out;
	   reg  [exp_width-1:0]       res_exp_c; 
	   wire [exp_width-1:0]       res_exp; 
	   reg                        res_msb;
	   wire [sig_width-1:0]       res_man;
	   wire                       res_sign;
	   wire                       res_man_z;  
	   wire [isize-1:0]           res;
	   wire [isize-1:0]           mod_res;
	   reg  [isize-1:0]           rounded;
	   reg  [isize-1:0]           z;
	   wire [w_isize-1:0]         lzd_cnt_a;
	   wire [w_isize-1:0]         lzd_cnt_b;
	   wire [exp_width-1:0]       exp_a;
	   wire [exp_width-1:0]       exp_b;
	   wire [sig_width-1:0]       nm_man_a;
	   wire [sig_width-1:0]       nm_man_b;
	   
	   
	   //Instantiate lzd here
	   lzd #(sig_width,w_isize) U_a(.a(a[sig_width-1:0]), .count(lzd_cnt_a));
	   lzd #(sig_width,w_isize) U_b(.a(b[sig_width-1:0]), .count(lzd_cnt_b));
	   
	   	   
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
		assign man_az = a[sig_width-1:0] == 0;
		assign man_bz = b[sig_width-1:0] == 0;
		assign nan_a = a[isize-2:sig_width] == {exp_width{1'b1}} && !man_az;
		assign nan_b = b[isize-2:sig_width] == {exp_width{1'b1}} && !man_bz;
		assign inf_a = a[isize-2:sig_width] == {exp_width{1'b1}} && man_az;
		assign inf_b = b[isize-2:sig_width] == {exp_width{1'b1}} && man_bz;
		assign a_z = chk_eaz && man_az;
		assign b_z = chk_ebz && man_bz;

	/****************************
	*Taking care of denormals: convert denormals to normals by lzd and lsh
	*
	****************************/
	assign nm_man_a = a[sig_width-1:0] << lzd_cnt_a;
	assign nm_man_b = b[sig_width-1:0] << lzd_cnt_b;
	
	//decide exp here based on normals and denormals 
	assign exp_a = chk_eaz ? {{exp_width-w_isize{1'b0}}, lzd_cnt_a} : a[isize-2:sig_width];
	assign exp_b = chk_ebz ? {{exp_width-w_isize{1'b0}}, lzd_cnt_b} : b[isize-2:sig_width];	
	
	//Subtract the exponents			  
	assign s1 = exp_a - exp_b;
    assign bias_add_exp = s1 + bias_value;
		
	//Divide the mantissas - add hidden bit first
	assign man_a = chk_eaz ? {nm_man_a,1'b0} : {1'b1,a[sig_width-1:0]};
	assign man_b = chk_ebz ? {nm_man_b,1'b0} : {1'b1,b[sig_width-1:0]}; 	 
	
	//Decide the shift based on mantissa comparision
	assign cp_man = man_a < man_b;
	
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
	assign rem_z = b_z ? 1 : rem == 0;	   
	   //Calculate the result
	   assign lsh_out = cp_man ? {quot[sig_width+1:0],1'b0} : quot[sig_width+2:0];
	   //In case of denormals, the value is always < 1 and on normalizing the exp becomes -ve
	   // and when this no. is divided by normaliszed no. with +ve exp, the result becomes tiny
	   //and result is denormalised by shifting the q to right.  
	   wire [exp_width-1:0] temp_add = chk_eaz ? exp_a + exp_b : ~s1+1'b1;
	   assign rsh_cnt = temp_add - {1'b0,{exp_width-2{1'b1}},1'b0}; //7E for single precision
   	   assign rsh_cnt_sat = rsh_cnt > (sig_width+1) ? (sig_width+2) : rsh_cnt;
	   assign rsh_out = quot[sig_width+2:0] >> rsh_cnt_sat;	   
	   assign res_man = tiny ? rsh_out[sig_width+1:2] : lsh_out[sig_width+1:2];	
	   always @(*) 
		case ({chk_eaz, chk_ebz})
		   2'b10: {res_msb,res_exp_c} = (bias_add_exp - cp_man) - {lzd_cnt_a,1'b0}; //res_msb sets tiny
		   2'b01: {res_msb,res_exp_c} = (bias_add_exp - cp_man) + {lzd_cnt_b,1'b0}; //res_msb sets huge
		   2'b11: {res_msb,res_exp_c} = (bias_add_exp - cp_man) - {lzd_cnt_a,1'b0} + {lzd_cnt_b,1'b0};
		   default: {res_msb,res_exp_c} = (bias_add_exp - cp_man);
		endcase
	   assign res_exp = tiny ? 0 : res_exp_c;	   
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
					if ( tiny )
						begin
							if ((!rsh_out[2] && rsh_out[1] && !rsh_out[0] && rem_z ) || !rsh_out[1])
								rounded = res;
							else
								rounded = mod_res;
						end
					else
						begin 
							if ((!lsh_out[2] && lsh_out[1] && !rsh_out[0] && rem_z ) || !lsh_out[1])
								rounded = res;
							else 
								rounded = mod_res;					
						end
			   3'b001:  rounded = res;
			   3'b010:  rounded = res_sign ? res : mod_res;
			   3'b011:  rounded = res_sign ? mod_res : res;
			   3'b100:  if ( tiny )
				   begin 
					   if (rsh_out[1])
						   rounded = mod_res;
					   else
						   rounded = res;
				   end 
				   else 
					   begin 
						   if (lsh_out[1])
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
		   else if (infinity)   
			   z = {res_sign, {exp_width{1'b1}}, {sig_width{1'b0}}}; 			   
		   else if (huge) 	  
			   z = {res_sign, {exp_width-1{1'b1}}, 1'b0, {sig_width{1'b1}}}; 
		   else	if (a_z || (!inf_a && inf_b)) 
			   z = {res_sign, {isize-1{1'b0}}};
		   else			   			   
               z = inexact ? rounded :{res_sign, res_exp, res_man};				 
	   
	   assign zero = !invalid && ( a_z || (!inf_a && inf_b) || z[isize-2:0] == 0 );//(tiny && rnd!=2 && rnd !=3 && rnd != 5) || (tiny && rnd == 2 && res_sign) || (tiny && rnd == 3 && !res_sign));	   
	   assign infinity = !invalid && (inf_a ||b_z || (nan_a && !nan_b) || (huge && rnd!=1 && rnd != 2 && rnd !=3 ) || (huge && rnd == 2 && !res_sign) || (huge && rnd == 3 && res_sign)); 	   
	   assign invalid = (a_z && b_z) || (nan_a || nan_b) ||(inf_a && inf_b);// || (inf_a && nan_b) || (inf_b && nan_a); 
	   assign tiny = !invalid && !a_z && !inf_b && ((s1[exp_width] && (bias_add_exp[exp_width] || res_msb || res_exp_c == 0)) || (chk_eaz && (exp_b[exp_width-1] || exp_b[exp_width-1:0] == {exp_width-1{1'b1}})) || (bias_add_exp == 0 || bias_add_exp == 1 && cp_man) );
	   assign huge = !invalid && !b_z && ((!s1[exp_width] && bias_add_exp[exp_width] && !nan_a && !inf_a ) || (res_msb && chk_ebz && !nan_a && !inf_a) || (res_exp == {exp_width{1'b1}}));//( bias_add_exp == {exp_width{1'b1}} && res_exp == {exp_width{1'b1}}));
	   assign inexact = (!invalid && !inf_a && !b_z && (!rem_z || ( tiny ? |rsh_out[1:0] : |lsh_out[1:0]) || huge)) & ~div_by_zero;// || (tiny && (chk_eaz || chk_ebz))  ;//~(nan_a || nan_b) && ~(chk_ebz || chk_eaz);   
	   assign div_by_zero = b_z & ~a_z;

		 assign huge_out = huge & ~inf_a;

		 assign tiny_out = tiny & ~div_by_zero & ~infinity;
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
