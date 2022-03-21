
//--------------------------------------------------------------------------------------------------
//
// Title       : DW02_cos.v
// Design      : Trigonometric Functions


//-------------------------------------------------------------------------------------------------
//
// Description :  DW02_cos is a combinational cosine. This component takes the input angle A and
// calculates cos(pi x A). The input angle A is treated as a binary fixed point number which is
// converted to radians when multiplied by pi.
//
//-------------------------------------------------------------------------------------------------
`timescale 1ns / 10ps

module DW02_cos ( 
	              A,   //Angle in Binary 
	              COS  //Cos value of A
				  )/* synthesis syn_builtin_du = "weak" */;

parameter A_width = 16;
parameter cos_width = 32;

//Input/output declaration
input [ A_width - 1 : 0 ]    A;
output [ cos_width - 1 : 0 ] COS;

//Internal signal declaration
reg [ cos_width - 1 : 0 ] COS;
reg [ cos_width - 1 : 0 ] COS_res;	
reg [A_width - 1 : 0]     a_cur; 
reg                       zero;	   

// Function for LUT	 
function [31:0] cos_quarter;
input [5:0] input_val;
reg [31:0] temp;

begin
	case ( input_val )
		6'b000000: temp= 32'hffffffff;
		6'b000001: temp= 32'hffec4304;
		6'b000010: temp= 32'hffb10f1b;
		6'b000011: temp= 32'hff4e6d68;
		6'b000100: temp= 32'hfec46d1e;
		6'b000101: temp= 32'hfe132387;
		6'b000110: temp= 32'hfd3aabf8;
		6'b000111: temp= 32'hfc3b27d3;
		6'b001000: temp= 32'hfb14be7f;
		6'b001001: temp= 32'hf9c79d63;
		6'b001010: temp= 32'hf853f7dc;
		6'b001011: temp= 32'hf6ba073b;
		6'b001100: temp= 32'hf4fa0ab6;
		6'b001101: temp= 32'hf3144762;
		6'b001110: temp= 32'hf1090827;
		6'b001111: temp= 32'heed89db6;
		6'b010000: temp= 32'hec835e79;
		6'b010001: temp= 32'hea09a68a;
		6'b010010: temp= 32'he76bd7a1;
		6'b010011: temp= 32'he4aa5909;
		6'b010100: temp= 32'he1c5978c;
		6'b010101: temp= 32'hdebe0563;
		6'b010110: temp= 32'hdb941a28;
		6'b010111: temp= 32'hd84852c0;
		6'b011000: temp= 32'hd4db3148;
		6'b011001: temp= 32'hd14d3d02;
		6'b011010: temp= 32'hcd9f023f;
		6'b011011: temp= 32'hc9d1124c;
		6'b011100: temp= 32'hc5e40358;
		6'b011101: temp= 32'hc1d8705f; 
		6'b011110: temp= 32'hbdaef913; 
		6'b011111: temp= 32'hb96841bf; 
		6'b100000: temp= 32'hb504f333; 
		6'b100001: temp= 32'hb085baa8; 
		6'b100010: temp= 32'habeb49a4; 
		6'b100011: temp= 32'ha73655df; 
		6'b100100: temp= 32'ha2679928; 
		6'b100101: temp= 32'h9d7fd149; 
		6'b100110: temp= 32'h987fbfe7; 
		6'b100111: temp= 32'h93682a66; 
		6'b101000: temp= 32'h8e39d9cd; 
		6'b101001: temp= 32'h88f59aa0; 
		6'b101010: temp= 32'h839c3cc9; 
		6'b101011: temp= 32'h7e2e936f; 
		6'b101100: temp= 32'h78ad74e0; 
		6'b101101: temp= 32'h7319ba64; 
		6'b101110: temp= 32'h6d744027; 
		6'b101111: temp= 32'h67bde50e; 
		6'b110000: temp= 32'h61f78a9a; 
		6'b110001: temp= 32'h5c2214c3; 
		6'b110010: temp= 32'h563e69d6; 
		6'b110011: temp= 32'h504d7250; 
		6'b110100: temp= 32'h4a5018bb; 
		6'b110101: temp= 32'h4447498a; 
		6'b110110: temp= 32'h3e33f2f6; 
		6'b110111: temp= 32'h381704d4; 
		6'b111000: temp= 32'h31f17078; 
		6'b111001: temp= 32'h2bc42889; 
		6'b111010: temp= 32'h259020dd; 
		6'b111011: temp= 32'h1f564e56; 
		6'b111100: temp= 32'h1917a6bc; 
		6'b111101: temp= 32'h12d52092; 
		6'b111110: temp= 32'h0c8fb2f8; 
		6'b111111: temp= 32'h0648557d; 
 		default  : temp= 32'h0;
	endcase
	cos_quarter = temp;
end 
endfunction	 
//End of function


//Function to return delta values - these are constants (Max. 27 bits)
//Subtract sample1 from sample2 - the values are -ve assign sample1 value > sample2 value
//Take 2's complement values are tabulated here. Hence result1 is -ve
//The delta for 3f is calculated by taking 65th sample
function [26:0] cos_delta;
input [5:0] input_val;
reg [26:0] temp;

begin
	case ( input_val )
		6'b000000: temp= 27'h013bcfb;//forward interpolation
		6'b000001: temp= 27'h03b33e9;
		6'b000010: temp= 27'h062a1b3;
		6'b000011: temp= 27'h08a004a;
		6'b000100: temp= 27'h0b14997;
		6'b000101: temp= 27'h0d8778f;
		6'b000110: temp= 27'h0ff8425;
		6'b000111: temp= 27'h1266954;
		6'b001000: temp= 27'h14d211c;
		6'b001001: temp= 27'h173a587;
		6'b001010: temp= 27'h199f0a1;
		6'b001011: temp= 27'h1bffc85;
		6'b001100: temp= 27'h1e5c354;
		6'b001101: temp= 27'h20b3f3b;
		6'b001110: temp= 27'h2306a71;
		6'b001111: temp= 27'h2553f3d;
		6'b010000: temp= 27'h279b7ef;
		6'b010001: temp= 27'h29dcee9;
		6'b010010: temp= 27'h2c17e98;
		6'b010011: temp= 27'h2e4c17d;
		6'b010100: temp= 27'h3079229;
		6'b010101: temp= 27'h329eb3b;
		6'b010110: temp= 27'h34bc768;
		6'b010111: temp= 27'h36d2178;
		6'b011000: temp= 27'h38df446;
		6'b011001: temp= 27'h3ae3ac3;
		6'b011010: temp= 27'h3cdeff3;
		6'b011011: temp= 27'h3ed0ef4;
		6'b011100: temp= 27'h40b92f9;
		6'b011101: temp= 27'h429774c;
		6'b011110: temp= 27'h446b754;
		6'b011111: temp= 27'h4634e8c;
		6'b100000: temp= 27'h47f388b;
		6'b100001: temp= 27'h49a7104;
		6'b100010: temp= 27'h4b4f3c5;
		6'b100011: temp= 27'h4cebcb7;
		6'b100100: temp= 27'h4e7c7df;
		6'b100101: temp= 27'h5001162;
		6'b100110: temp= 27'h5179581;
		6'b100111: temp= 27'h52e5099;
		6'b101000: temp= 27'h5443f2d;
		6'b101001: temp= 27'h5595dd7;
		6'b101010: temp= 27'h56da95a;
		6'b101011: temp= 27'h5811e8f;
		6'b101100: temp= 27'h593ba7c;
		6'b101101: temp= 27'h5a57a3d;
		6'b101110: temp= 27'h5b65b19;
		6'b101111: temp= 27'h5c65a74;
		6'b110000: temp= 27'h5d575d7;
		6'b110001: temp= 27'h5e3aaed;
		6'b110010: temp= 27'h5f0f786;
		6'b110011: temp= 27'h5fd5995;
		6'b110100: temp= 27'h608cf31;
		6'b110101: temp= 27'h6135694;
		6'b110110: temp= 27'h61cee22;
		6'b110111: temp= 27'h625945c;
		6'b111000: temp= 27'h62d47ef;
		6'b111001: temp= 27'h63407ac;
		6'b111010: temp= 27'h639d287;
		6'b111011: temp= 27'h63ea79a;
		6'b111100: temp= 27'h642862a;
		6'b111101: temp= 27'h6456d9a;
		6'b111110: temp= 27'h6475d7b; 
		6'b111111: temp= 27'h648557d;
 		default  : temp= 27'h0;
	endcase
	cos_delta = temp;
end 
endfunction	 
//End of linear function

// Function to return delta**2/2 values - these are constants	 
function [20:0] cos_delta2;
input [5:0] input_val;
reg [20:0] temp;

begin
	case ( input_val )
		6'b000000: temp= 21'h13bb77;
		6'b000001: temp= 21'h13b6e5;
		6'b000010: temp= 21'h13af4b;
		6'b000011: temp= 21'h13a4a6;
		6'b000100: temp= 21'h1396fc;
		6'b000101: temp= 21'h13864b;
		6'b000110: temp= 21'h137297;
		6'b000111: temp= 21'h135be4;
		6'b001000: temp= 21'h134235;
		6'b001001: temp= 21'h13258d;
		6'b001010: temp= 21'h1305f2;
		6'b001011: temp= 21'h12e367;
		6'b001100: temp= 21'h12bdf3;
		6'b001101: temp= 21'h12959b;
		6'b001110: temp= 21'h126a66;
		6'b001111: temp= 21'h123c59;
		6'b010000: temp= 21'h120b7d;
		6'b010001: temp= 21'h11d7d7;
		6'b010010: temp= 21'h11a172;
		6'b010011: temp= 21'h116856;
		6'b010100: temp= 21'h112c89;
		6'b010101: temp= 21'h10ee16;
		6'b010110: temp= 21'h10ad08;
		6'b010111: temp= 21'h106967;
		6'b011000: temp= 21'h10233e;
		6'b011001: temp= 21'h0fda98;
		6'b011010: temp= 21'h0f8f80;
		6'b011011: temp= 21'h0f4202;
		6'b011100: temp= 21'h0ef229;
		6'b011101: temp= 21'h0ea004;
		6'b011110: temp= 21'h0e4b9c;
		6'b011111: temp= 21'h0df4ff;
		6'b100000: temp= 21'h0d9c3c;
		6'b100001: temp= 21'h0d4160;
		6'b100010: temp= 21'h0ce479;
		6'b100011: temp= 21'h0c8594;
		6'b100100: temp= 21'h0c24c1;
		6'b100101: temp= 21'h0bc20f;
		6'b100110: temp= 21'h0b5d8c;
		6'b100111: temp= 21'h0af74a;
		6'b101000: temp= 21'h0a8f55;
		6'b101001: temp= 21'h0a25c1;
		6'b101010: temp= 21'h09ba9a;
		6'b101011: temp= 21'h094df6;
		6'b101100: temp= 21'h08dfe0;
		6'b101101: temp= 21'h08706e;
		6'b101110: temp= 21'h07ffad;
		6'b101111: temp= 21'h078db1;
		6'b110000: temp= 21'h071a8b;
		6'b110001: temp= 21'h06a64c;
		6'b110010: temp= 21'h063107;
		6'b110011: temp= 21'h05bace;
		6'b110100: temp= 21'h0543b1;
		6'b110101: temp= 21'h04cbc7;
		6'b110110: temp= 21'h04531d;
		6'b110111: temp= 21'h03d9c9;
		6'b111000: temp= 21'h035fde;
		6'b111001: temp= 21'h02e56d;
		6'b111010: temp= 21'h026a89;
		6'b111011: temp= 21'h01ef48;
		6'b111100: temp= 21'h0173b8;
		6'b111101: temp= 21'h00f7f0;
		6'b111110: temp= 21'h007c01;
		6'b111111: temp= 21'h0; 
 		default  : temp= 21'h0;
	endcase
	cos_delta2 = temp;
end 
endfunction	 
//End of quad function	  

// Function to return delta**3/6 values - these are constants (max. 14 bits)
//delta3 for 3e and 3f are calculated by taking extra 1/2 samples after 64th sample.
//For cubic interpolation two samples before "dp" and two after are considered.	
function [15:0] cos_delta3;
input [5:0] input_val;
reg [15:0] temp;

begin
	case ( input_val )
		6'b000000: temp= 16'h0186;
		6'b000001: temp= 16'h0186;
		6'b000010: temp= 16'h0288;
		6'b000011: temp= 16'h038c;
		6'b000100: temp= 16'h048e;
		6'b000101: temp= 16'h0590;
		6'b000110: temp= 16'h0691;
		6'b000111: temp= 16'h0791;
		6'b001000: temp= 16'h088f;
		6'b001001: temp= 16'h098d;
		6'b001010: temp= 16'h0a89;
		6'b001011: temp= 16'h0b83;
		6'b001100: temp= 16'h0c7c;
		6'b001101: temp= 16'h0d72;
		6'b001110: temp= 16'h0e67;
		6'b001111: temp= 16'h0f59;
		6'b010000: temp= 16'h1049;
		6'b010001: temp= 16'h1137;
		6'b010010: temp= 16'h1221;
		6'b010011: temp= 16'h1309;
		6'b010100: temp= 16'h13ef;
		6'b010101: temp= 16'h14d0;
		6'b010110: temp= 16'h15af;
		6'b010111: temp= 16'h168b;
		6'b011000: temp= 16'h1762;
		6'b011001: temp= 16'h1837;
		6'b011010: temp= 16'h1907;
		6'b011011: temp= 16'h19d4;
		6'b011100: temp= 16'h1a9d;
		6'b011101: temp= 16'h1b61;
		6'b011110: temp= 16'h1c22;
		6'b011111: temp= 16'h1cde;
		6'b100000: temp= 16'h1d96;
		6'b100001: temp= 16'h1e49;
		6'b100010: temp= 16'h1ef7;
		6'b100011: temp= 16'h1fa1;
		6'b100100: temp= 16'h2046;
		6'b100101: temp= 16'h20e6;
		6'b100110: temp= 16'h2181;
		6'b100111: temp= 16'h2216;
		6'b101000: temp= 16'h22a7;
		6'b101001: temp= 16'h2331;
		6'b101010: temp= 16'h23b7;
		6'b101011: temp= 16'h2436;
		6'b101100: temp= 16'h24b2;
		6'b101101: temp= 16'h2526;
		6'b101110: temp= 16'h2595;
		6'b101111: temp= 16'h25fe;
		6'b110000: temp= 16'h2662;
		6'b110001: temp= 16'h26bf;
		6'b110010: temp= 16'h2717;
		6'b110011: temp= 16'h2768;
		6'b110100: temp= 16'h27b4;
		6'b110101: temp= 16'h27f8;
		6'b110110: temp= 16'h2838;
		6'b110111: temp= 16'h2871;
		6'b111000: temp= 16'h28a3;
		6'b111001: temp= 16'h28d0;
		6'b111010: temp= 16'h28f6;
		6'b111011: temp= 16'h2915;
		6'b111100: temp= 16'h2930;
		6'b111101: temp= 16'h2942;
		6'b111110: temp= 16'h294f;
		6'b111111: temp= 16'h2955;
 		default  : temp= 16'h0;
	endcase				    
	cos_delta3 = temp;
end 
endfunction	 
//End of cubic function
					
//Implementation of Cosine functionality. The precision depends on parameters A_width and cos_width
always @ ( A )		  
	begin
		a_cur = (A[A_width-2]== 0 ) ? A : ( ~A + 1 ); 		
		if ( A_width == 2 )
			zero = A[0];
		else	
			zero = A[A_width-2] & ~(|A[A_width-3:0]); 
			
		if ( A_width <= 8 && A_width > 1 ) 
		begin:LUT
			reg               sign;
			reg [5:0]         a_dir;
			reg [33:0]        cos_dir_true;
 			reg [cos_width:0] cos_tmp;
			 
			sign = A[A_width-2] ^ A[A_width-1];	
		
			case ( A_width )
				2 : a_dir = 0;
				3 : a_dir = { a_cur[0], 5'b0 };
				4 : a_dir = { a_cur[1:0], 4'b0 };
				5 : a_dir = { a_cur[2:0], 3'b0 };
				6 : a_dir = { a_cur[3:0], 2'b0 };
				7 : a_dir = { a_cur[4:0], 1'b0 };
				8 : a_dir =  a_cur[5:0];
			endcase
			
			cos_dir_true = a_dir == 0 ? {2'b01,32'b0}: {2'b00,cos_quarter(a_dir)}; 
			
			if (cos_width != 34)
				begin
					if ( sign )
						cos_tmp = ~cos_dir_true[33:33-cos_width];
					else
						cos_tmp = cos_dir_true[33:33-cos_width];
			        cos_tmp = cos_tmp + 1;
					COS_res = cos_tmp[cos_width:1];					
				end
			else	
				begin
					if ( sign )
						cos_tmp = ~cos_dir_true+1;
					else
						cos_tmp = cos_dir_true;	
				    COS_res = cos_tmp;
				end
		end
  
        // For A_width > 8 and cos_width <= 16 : Linear Interpolation technique	 
		//result = f(xj) - (n * delta)/h	
		else if  ( cos_width <= 16 )   
			begin: linear	
        reg [A_width - 9 : 0]     delta_diff;
				reg [5:0]                 xj_lut;
				reg [31:0]                f_xj; 
				reg [26:0]                delta_fx; 
				reg [31:0]                delta_div;			  
				reg [31:0]                lin_prod_low;
        reg [cos_width - 3:0]     output_dir;	
        reg [cos_width - 3:0]     output_dir_1;	
        reg [cos_width - 1 :0]    cos_00; 
				reg [cos_width - 1 :0]    cos_01; 
				reg [cos_width - 1 :0]    cos_10; 
				reg [cos_width - 1 :0]    cos_11; 
				
		    xj_lut =  a_cur[A_width-3:(A_width-3)-5]; // Six bits assigned to xj_lut for
 
				// To find n value	
                                                                                                                                     
				delta_diff = a_cur[(A_width > 9 ? A_width - 9 : 0) :0]; // n = x - xj 
                
				//data points from look up table, 32 bit data.

				f_xj = cos_quarter(xj_lut);
 
				delta_fx = cos_delta(xj_lut);//Get f(xj) - f(xj_1)
				
				// finding slope: using 16 bit multiplication
				if ( A_width >= 24 )
					begin 					
						lin_prod_low = delta_diff[(A_width >= 24 ? A_width-9 : 0) : (A_width >= 24 ? A_width - 24 : 0)] * delta_fx[26:12];//16-bit x 16-bit
            delta_div = lin_prod_low[31:4]; //division calculation->(A_width-8)-(A_width-8-16)-12 -> h - (n(16bits) + remaining bits) - 12 ( constant, delta_1) 
					end
				else
					begin
						//delta_diff is always < 16 bits and hence padded with 0's. Which results initial multiplying.
						// positions properly to divide the result from h( actually it is equivalent to Xing and / ing by a constant.	
						//lin_prod_low = delta_diff * delta_fx[31:A_width-8];//requires more resource-> odd size multiplier                                                

						lin_prod_low = delta_diff * delta_fx[26:A_width-8];//division first, multiplication next
	          delta_div = lin_prod_low;
					end	
				
 				//Linear interpolation	  
				if ( A_width < cos_width )
					begin: save_area 
						reg [cos_width-3:0]       result0;
				    reg [cos_width-3:0]       result0_compliment;						
						result0 = f_xj[31:(34-cos_width)] - delta_div[31:(34-cos_width)];//Max. 14 bit subtraction
						result0_compliment = (~result0) + 1;
						output_dir = result0;                                                                     
						output_dir_1 = result0_compliment; 						
					end	 
				else
					begin: more_area
						reg [31:0]       result0;
						reg [31:0]       result0_compliment;
						result0 = f_xj - delta_div;//Max. 14 bit subtraction
						result0_compliment = (~result0) + 1; 
						output_dir = result0[31:34-cos_width];                                                                    
				    output_dir_1 = result0_compliment[31:34-cos_width]; 
					end
					
				//Output assignment
				
				cos_00 = a_cur[A_width-3:0]== 0 ? {2'b01,{cos_width-2{1'b0}}} : {2'b0, output_dir};
 
				cos_01 = a_cur[A_width-3:0]== 0 ? 0 : {2'b11, output_dir_1};

				cos_10 = {2'b11, output_dir_1};

				cos_11 = a_cur[A_width-3:0]== 0 ? 0 : {2'b0, output_dir};
                                                    
			    if ( A[A_width - 1:A_width - 2] == 2'b00 ) 
			 		  COS_res = cos_00;       
			   	else if ( A[A_width - 1:A_width - 2] == 2'b01 )    
			 		  COS_res = cos_01;       
			   	else if ( A[A_width - 1:A_width - 2] == 2'b10 )   
			 		  COS_res = cos_10;	      
			   	else if ( A[A_width - 1:A_width - 2] == 2'b11 )   
			 		  COS_res = cos_11;	      
			end  
	  
      // For A_width > 8 and cos_width >16 and cos_width <= 24 : Quadratic Interpolation technique
      //result = f(xj) - (n * delta)/h + (n * h_n)/h**2 (delta_2/2)	
			else if ( cos_width <= 24 )
				begin:quad
					reg [5:0]               xj_lut; 
					reg [31:0]              f_xj; 
					reg [26:0]              delta_1; 
          reg [A_width - 9 : 0]   delta_diff;
					reg [20:0]              delta_2_shift;
					reg [31:0]              result_1;
					reg [31:0]              result_2;
					reg [cos_width-3:0]     result0;
					reg [cos_width-3:0]     result0_compliment;	
					reg [31:0]              lin_prod_low; 
					reg [31:0]              quad_prod1_high;
					reg [31:0]              quad_prod1_low;
					reg [A_width-9:0]	    	n;
					reg [A_width-8:0]	    	n_h;
					reg [A_width-9:0]	    	h_n;
          reg [cos_width - 3:0]   output_dir;	
          reg [cos_width - 3:0]   output_dir_1;	
          reg [cos_width - 1 :0]  cos_00; 
					reg [cos_width - 1 :0]  cos_01; 
					reg [cos_width - 1 :0]  cos_10; 
					reg [cos_width - 1 :0]  cos_11; 

					xj_lut =  a_cur[A_width - 3 : (A_width - 3) - 5]; // Six bits assigned to xj_lut for LUT 
						
          //For the first term
	        f_xj = cos_quarter(xj_lut);  
			    delta_1 = cos_delta(xj_lut);//Get f(xj_1) - f(xj)
					delta_diff =  a_cur[(A_width > 9 ? A_width - 9 : 0 ):0];
					
					// finding slope: using 16 bit multiplication
					//Ex. A_width=16, n=92, delta_1 = 14d211c; lin_prod_low = 9200 x 14d2 = bdfc400
					//First term 
          if ( A_width >= 24 )
	         	begin
							lin_prod_low = delta_diff[(A_width >= 24 ? A_width-9 : 0) : (A_width >= 24 ? A_width - 24 : 0)] * delta_1[26:11];//16 x 16 
     	        result_1 = lin_prod_low[31:5]; //division calculation->(A_width-8)-(A_width-8-16)-11 -> h - (n(16bits) + remaining bits) - 12 ( constant, delta_1)
						end  
					 else if ( A_width >= 13 )
						begin                  
							lin_prod_low = delta_diff * delta_1[26:(26-(31-(A_width-8)))];//32-bit result always 
              result_1 = lin_prod_low[31:((A_width-8) - (26-(31-(A_width-8))))]; //00bdfc40 
						end	                 
					else
						begin                                                                          
							lin_prod_low = delta_diff * delta_1;//multiplication first                                                                                          
              result_1 = lin_prod_low[31:(A_width-8)]; //division next 
						end	                
 
				   delta_2_shift = cos_delta2(xj_lut);
				   n = delta_diff;
				   n_h = ~({1'b1,n}) + 1;// n-h	 1-bit more than n 
				   h_n = n_h;//+ve	But this width is always <= n. for Ex. n= 35, n_h=135, h_n=cb..n=FE12, n_h = 1FE12, but h_n=1EE
	
					if ( A_width > 24 )  
						begin 
							quad_prod1_low = n[(A_width >= 24 ? A_width-9 : 0) : (A_width >= 24 ? A_width - 24 : 0)] * h_n[(A_width >= 24 ? A_width-9 : 0) : (A_width >= 24 ? A_width - 24 : 0)];
							{quad_prod1_high, quad_prod1_low} = quad_prod1_low[31:16] *  delta_2_shift;
							result_2 = 	{quad_prod1_high[4:0],quad_prod1_low[31:16]};
						end  
					else if ( A_width < 16 ) 
						begin                 
				    	quad_prod1_low = n * h_n;//7x7 = 14 bit result.
				    	{quad_prod1_high, quad_prod1_low} = {quad_prod1_low,{(16-((A_width-8)*2)){1'b0}}} *  delta_2_shift;//first 16-bits are 0--16 x 24 = 40 bits
							result_2 = 	{quad_prod1_high[4:0],quad_prod1_low[31:16]};
						end	
					else if ( A_width == 16 ) 
						begin                  
				    		quad_prod1_low = n * h_n;//8x8 = 16 bit result.
				    		{quad_prod1_high, quad_prod1_low} = quad_prod1_low[15:0] * delta_2_shift;//first 16-bits are 0--16 x 24 = 40 bits
							result_2 = 	{quad_prod1_high[4:0],quad_prod1_low[31:16]};
						end	
					else
						begin 
							quad_prod1_low = n * h_n;//16(max) x 16(max) = 32(max) result.
							{quad_prod1_high, quad_prod1_low} = quad_prod1_low[((A_width-8)*2)-1:((A_width-8)*2)-16 ] * delta_2_shift;//16 X 16 = 32
							result_2 = 	{quad_prod1_high[4:0],quad_prod1_low[31:16]};
						end	   
				
			     result0 = f_xj[31:(34-cos_width)] -  result_1[31:(34-cos_width)] + result_2[31:(34-cos_width)];
   		     result0_compliment = (~result0) + 1;	  
				   
				   output_dir = result0;
				   output_dir_1 = result0_compliment;

				   cos_00 = a_cur[A_width-3:0]== 0 ? {2'b01,{cos_width-2{1'b0}}} : {2'b0, output_dir};                                                                                                                                                          
				   cos_01 = a_cur[A_width-3:0]== 0 ? 0 : {2'b11, output_dir_1};                                                                                                                                          
				   cos_10 = {2'b11, output_dir_1};                                                                                                                                          
				   cos_11 = a_cur[A_width-3:0]== 0 ? 0 : {2'b0, output_dir}; 
				   
			       if ( A[A_width - 1:A_width - 2] == 2'b00 )        
			 	   	  COS_res = cos_00;       
			   	   else if ( A[A_width - 1:A_width - 2] == 2'b01 )    
			 	   	  COS_res = cos_01;       
			   	   else if ( A[A_width - 1:A_width - 2] == 2'b10 )   
			 	   	  COS_res = cos_10;	      
			   	   else if ( A[A_width - 1:A_width - 2] == 2'b11 )   
			 	   	  COS_res = cos_11;	      
				end
		
	    		//For A_width > 8 and cos_width >24 and cos_width <= 34 : Cubic Interpolation technique
	      else if ( cos_width <= 34 )
					begin:cubic	
						reg [5:0]               xj_lut;                               
						reg [31:0]              f_xj;                              
            reg [A_width - 9 : 0]   delta_diff;
						reg [26:0]              delta_1;            
						reg [20:0]              delta_2_shift;      
						reg [15:0]              delta_3;            
						reg [31:0]              result_1;           
						reg [31:0]              result_2;           
						reg [31:0]              result_3;           
				    reg [cos_width-3:0]     result0;
					  reg [cos_width-3:0]     result0_compliment;	
						reg [31:0]              lin_prod_low;       
						reg [31:0]              lin_prod_high;       
						reg [31:0]              quad_prod1_high;    
						reg [31:0]              quad_prod1_low;     
						reg [31:0]              quad_prod_low;     
						reg [31:0]              cube_prod1_high;    
						reg [31:0]              cube_prod2;         
					  reg [A_width-9:0]		n;                  
					  reg [A_width-8:0]		n_h;                
					  reg [A_width-9:0]		h_n;                
						reg [A_width-8:0]	 	n_2h;               
            reg [cos_width - 3:0]   output_dir;	
            reg [cos_width - 3:0]   output_dir_1;
            reg [cos_width - 1 :0]  cos_00; 
						reg [cos_width - 1 :0]  cos_01; 
						reg [cos_width - 1 :0]  cos_10; 
						reg [cos_width - 1 :0]  cos_11; 


						xj_lut = a_cur[A_width - 3 : (A_width - 3) - 5]; // Six bits assigned to xj_lut for LUT 
						f_xj = cos_quarter(xj_lut);	   
													
					  delta_diff =  a_cur[(A_width > 9 ? A_width - 9 : 0 ):0];
				    delta_1 = cos_delta(xj_lut);//Get f(xj) - f(xj_1)

						//First term 
						{lin_prod_high,lin_prod_low} = delta_diff * delta_1;
						result_1 = {lin_prod_high[(A_width-8-1 > 0 ? A_width-8-1 : 0)  :0],lin_prod_low[31:(A_width > 8 ? A_width - 8 : 0)]}; 
 					   
						//Second term 
						delta_2_shift = cos_delta2(xj_lut);	
						n = delta_diff;
						n_h = ~({1'b1,n}) + 1;// n-h	 1-bit more than n 
						h_n = n_h;//+ve	But this width is always <= n. for Ex. n= 35, n_h=135, h_n=cb..n=FE12, n_h = 1FE12, but h_n=1EE
																						
						if ( A_width > 24 )
						begin
							quad_prod1_low = n[(A_width >= 24 ? A_width-9 : 0) : (A_width >= 24 ? A_width - 24 : 0)] * h_n[(A_width >= 24 ? A_width-9 : 0) : (A_width >= 24 ? A_width - 24 : 0)];
							{quad_prod1_high, quad_prod_low} = quad_prod1_low[31:16] * delta_2_shift;
							result_2 = 	{quad_prod1_high[4:0],quad_prod_low[31:16]};
						end 
						else if ( A_width < 16 )
						begin
				    	quad_prod1_low = n * h_n;//7x7 = 14 bit result.
				    	{quad_prod1_high, quad_prod_low} = {quad_prod1_low,{(16-((A_width-8)*2)){1'b0}}} *  delta_2_shift;//first 16-bits are 0--16 x 24 = 40 bits
							result_2 = {quad_prod1_high[4:0],quad_prod_low[31:16]};
						end	
						else if ( A_width == 16 )
						begin 
				    	quad_prod1_low = n * h_n;//8x8 = 16 bit result.
				    	{quad_prod1_high, quad_prod_low} = quad_prod1_low[15:0] * delta_2_shift;//first 16-bits are 0--16 x 24 = 40 bits
							result_2 = 	{quad_prod1_high[4:0],quad_prod_low[31:16]};
						end	
						else
						begin
							quad_prod1_low = n * h_n;//16(max) x 16(max) = 32(max) result.
							{quad_prod1_high, quad_prod_low} = quad_prod1_low[((A_width-8)*2)-1:((A_width-8)*2)-16 ] * delta_2_shift;//16 X 16 = 32
							result_2 = 	{quad_prod1_high[4:0],quad_prod_low[31:16]};
						end	   
						
						//Third term	
						delta_3 = cos_delta3(xj_lut);	
						n_2h = {1'b1,h_n};//~({1'b0,n}) + 1'b1;//~({2'b10,n}) + 1'b1;   results are same

					  if ( A_width >= 24 )
							begin
								cube_prod1_high = quad_prod1_low[31:16] * n_2h[(A_width >= 24 ? A_width - 8 : 0) : (A_width >= 24 ? A_width-24 : 0)];// divide by h
								cube_prod2 = cube_prod1_high[31:16] * delta_3;// divide by h
								result_3 = {16'b0,cube_prod2[31:16]};//divide by h
							end 
						else if ( A_width < 16 )
							begin
								cube_prod1_high = quad_prod1_low * n_2h;//7 * 7 = 14-bits(max)
								cube_prod2 = (A_width == 14 || A_width == 15) ? cube_prod1_high[21:A_width-8] * delta_3 : cube_prod1_high * delta_3;//A_width=14 or 15, perform (n*n_h)/h * delta_3
								result_3 = (A_width == 14 || A_width == 15) ? cube_prod2[31:((A_width > 8 && A_width < 16)  ? A_width - 8 : 0 )*2] : cube_prod2[31:((A_width > 8 && A_width < 16) ? A_width - 8 : 0 )*3];//cube_prod2/h**2 or cube_prod2/h**3 based on width
							end	
						else if ( A_width == 16 )
							begin
								cube_prod1_high = quad_prod1_low[15:0] * n_2h;//first 16-bits are 0--16 x 8 = 24
								cube_prod2 = cube_prod1_high[23:8] * delta_3;//16 x 32 = 48 bits
								result_3 = {16'b0,cube_prod2[31:16]};
							end	
						else
							begin
								cube_prod1_high = quad_prod1_low[31:A_width-8] * n_2h;//16(max) x 16(max) = 32(max) result.
								cube_prod2 = cube_prod1_high[31:A_width-8] * delta_3;//16 x 32 = 48 bits
								result_3 = cube_prod2[31:A_width-8];
							end	
						 
						result0 = f_xj[31:(34-cos_width)] -  result_1[31:(34-cos_width)] + result_2[31:(34-cos_width)] + result_3[31:(34-cos_width)];
			
						result0_compliment = (~result0) + 1;
				    output_dir = result0;
				    output_dir_1 = result0_compliment;
			
						cos_00 = a_cur[A_width-3:0]== 0 ? {2'b01,{cos_width-2{1'b0}}} : {2'b0, output_dir};
				    cos_01 = a_cur[A_width-3:0]== 0 ? 0 : {2'b11, output_dir_1};
				    cos_10 = {2'b11, output_dir_1};
				    cos_11 = a_cur[A_width-3:0]== 0 ? 0 : {2'b0, output_dir};
 						
			    	if ( A[A_width - 1:A_width - 2] == 2'b00 )
			 				COS_res = cos_00;                               
			   		else if ( A[A_width - 1:A_width - 2] == 2'b01 )       
			 				  COS_res = cos_01;                               
			   		else if ( A[A_width - 1:A_width - 2] == 2'b10 )       
			 				  COS_res = cos_10;	                              
			   		else if ( A[A_width - 1:A_width - 2] == 2'b11 )       
			 				  COS_res = cos_11;
					end
        end	  
		
//Update the output
always @ ( A or COS_res or zero )
	if ( zero )
		COS = 0;
	else
		COS = COS_res;	 

endmodule
