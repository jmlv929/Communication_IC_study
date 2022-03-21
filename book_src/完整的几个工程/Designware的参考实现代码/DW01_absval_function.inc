
//-----------------------------------------------------------------------------------
//
// ABSTRACT:  Absolute Value
//           This operator assumes that the input A is coded as a two's 
//           complement number.  The sign std_logic A(n-1) determines whether
//           the input is positive or negative.
//
//           A(n-1)     ABSVAL
//           -------+----------
//            '0'   |    A
//            '1'   |   -A
//
//           The value -A is computed as (A') + '1'
//
// MODIFIED: Arvind:    07/30/97
//                      Converted module to function.
//
//	     Jay Zhu	10/14/1998 
//                      STAR 59348
//
//           RPH        07/17/2002 
//                      Rewrote to comply with the new guidelines
//   
//------------------------------------------------------------------------------

function[width-1 : 0] DWF_absval;

  // synopsys map_to_operator ABS_OP
  // synopsys return_port_name Z

  input  [width-1 : 0] A;
  begin
  // synopsys translate_off
   
  DWF_absval = ((^(A ^ A) !== 1'b0)) ? {width{1'bx}} : 
		(A[width-1] == 1'b0) ? A : (-A);
  
  // synopsys translate_on
  end
endfunction


//  unified old inference name

function[width-1 : 0] DW_absval;
  // synopsys map_to_operator ABS_OP
  // synopsys return_port_name Z
 
  input  [width-1 : 0] A;
 
  DW_absval = DWF_absval(A); 
 
endfunction
