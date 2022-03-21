
//--------------------------------------------------------------------------------------------------
//
// Description : DW_norm_rnd is a general-purpose normalization and rounding module for a value
// represented in the sign-and-magnitude number system (a_sign, a_mag). The value
// represented in this system corresponds to (-1)^a_sign x a_mag. The magnitude of the number
// is a positive fixed-point value in the format a = (a0.a1 a2 a3 a4 a5 ...a[a_width-1]), where ai
// represents a bit. This means that a_mag has 1 integer bit and (a_width-1) fractional bits.
//
// The normalization process consists in generating an output in the range 1 ? b < 2
// (the output bit-vector has a 1 in the MS bit position) when there is a 1 bit in the search
// window provided as a parameter.
//
// The rounding is done using a method controlled by one of the component inputs. Output
// pos carries information about the position of binary point (exponent), and it is affected by
// the normalization shifts performed on the main input (a_mag)
//
//--------------------------------------------------------------------------------------------------

module DW_norm_rnd ( 
                  a_mag,       //Input data
                  a_sign,      // 0 - positive, 1 - negative
                  pos_offset,  //Offset value for the position of the binary point
                  sticky_bit,  //Indicates the presence of non-zero bits in fractional bit positions 
                               //beyond bit a_mag[a_width-1]
                  rnd_mode,    //Rounding mode
                               //000 – Round to nearest even
					 //001 – Round towards zero
					 //010 – Round to plus infinity
					 //011 – Round to minus infinity
					 //100 – Round up
					 //101 – Round away from zero
                  no_detect,   //Result of search for the leading bit with value 1 in the search
                               //window: 0 - bit found, 1 - bit not found 
                  pos_err,     //Value provided at output pos is negative or cannot fit in an exp_width-bit
                  b,       //Normalized and rounded output data
                  pos          //pos_offset combined with the no. of bit positions the input a was
                               //shifted to the left(n): exp_ctr=0 -> pos_offset+n; 
                               //exp_ctr=1 -> pos_offset-n
                  )/* synthesis syn_builtin_du = "weak" */;

	parameter a_width = 16;   //Word length of a_mag
	parameter srch_wind = 4;  //Search window for the MS 1 bit(from left to right or from bit 0 to a_width-1)
      parameter exp_width = 4;  //Word length of exp_offset and pos	
      parameter b_width = 10;   //Word length of b
      parameter exp_ctr = 0;    //Controls computation of the binary point position (pos output)

      /************ Internal parameter *************/
       parameter RNE = 3'b000, RTZ = 3'b001, RPI = 3'b010, RMI = 3'b011, RUP = 3'b100, RAZ = 3'b101;
      /*********************************************/
      //Input/output declaration
	input	[a_width-1:0]		a_mag;
      input                         a_sign;
	input	[exp_width-1:0]		pos_offset;
      input                         sticky_bit;
	input	[2:0]		            rnd_mode;
	output				no_detect;
	output				pos_err;
	output [b_width-1:0]	      b;	
	output [exp_width-1:0]       	pos;

      //Internal signal declaration
	wire	[a_width-1:0]		b_norm;
	wire	[exp_width-1:0]		pos_norm;
      wire [exp_width-1:0]          pos_norm_mod;
      reg   [b_width-1:0]           rounded;
      wire  [b_width-1:0]           mod_res;
      wire                          co;
      reg  [exp_width-1:0]          pos;
      wire                          no_fit;
      reg                           pos_err;


      //Instantiation of DW_norm
      DW_norm #(a_width, srch_wind, exp_width, exp_ctr) norm ( 
                  .a(a_mag),           
                  .exp_offset(pos_offset),  
                  .no_detect(no_detect),
                  .ovfl(pos_err_i),        
                  .b(b_norm),           
                  .exp_adj(pos_norm) 
                  );

      //Extract round and sticky bits
      wire round = b_width == a_width ? 0 : b_norm[a_width-b_width-1];
      wire sticky = (a_width-b_width) < 2 ? sticky_bit : sticky_bit || (|b_norm[a_width-b_width-2:0]);
      wire [b_width-1:0] res = b_norm[a_width-1:a_width-b_width]; 
      assign {co,mod_res} = res + 1'b1;
      
      //RNE condition 
      wire detect_retain = (( !b_norm[a_width - b_width] && round && !sticky) || ~round );
      wire [b_width-1:0] adj_out = (co ? {1'b1,mod_res[b_width-1:1]} : mod_res);

      //Decide the output b, based on input rounding value
        always @(*)
        case (rnd_mode)
          RNE: if (detect_retain)
                  rounded = res;
               else
                  rounded = adj_out;
          RTZ: rounded = res;
          RPI: rounded = ~a_sign && (round || sticky) ? adj_out : res;
          RMI: rounded = a_sign && (round || sticky) ? adj_out : res;
          RUP: rounded = round ? adj_out : res;
          RAZ: rounded = (round || sticky) ? adj_out : res;
          default: rounded = res;
        endcase


      //Incrementor/decrementor for adjusting the pos_offset: needed when value exceeds 2 or drops below 1
      assign {no_fit, pos_norm_mod} = exp_ctr ? pos_norm + 1'b1 : pos_norm - 1'b1;

      //Decide the output pos, based on input rounding value
      always @(*)
        case (rnd_mode)
          RNE: pos =  ~detect_retain && co ?  pos_norm_mod : pos_norm; 
          RTZ: pos = pos_norm; 
          RPI: pos = ~a_sign && (round || sticky) && co ? pos_norm_mod : pos_norm;  
          RMI: pos = a_sign && (round || sticky) && co ? pos_norm_mod : pos_norm; 
          RUP: pos = round && co ? pos_norm_mod : pos_norm; 
          RAZ: pos = (round || sticky ) && co ? pos_norm_mod : pos_norm;
          default: pos = pos_norm; 
        endcase

      //Decide the ouput pos_err based on input rounding value
      always @(*)
        case (rnd_mode)
          RNE: pos_err = ~detect_retain && co && no_fit ?  ~pos_err_i: pos_err_i; 
          RTZ: pos_err = pos_err_i; 
          RPI: pos_err = ~a_sign && (round || sticky) && co && no_fit ? ~pos_err_i : pos_err_i; 
          RMI: pos_err = a_sign && (round || sticky) && co && no_fit ? ~pos_err_i : pos_err_i; 
          RUP: pos_err = co && round && no_fit ? ~pos_err_i : pos_err_i; //pos_err_i; 
          RAZ: pos_err = co && (round || sticky ) && no_fit ? ~pos_err_i : pos_err_i; //pos_err_i; 
          default: pos_err = pos_err_i; 
        endcase

      wire [b_width-1:0] b = rounded;

endmodule
