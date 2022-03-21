
//
////////////////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------------------
//
// ABSTRACT: Parity Generation
//           parameterizable bus size (width > 0), parameteric "odd/even"
//           par_type 1 = odd; par_type 0 = even 
//           datain     - input data to system register.
//           parity     - output parity bit(s).
//
// Modified: 11/02/98 Jay Zhu STAR 59348
//
/////////////////////////////////////////////////////////////////
//
// WARNING: This is an obsoleted function.  Using this function
//	may cause bad logic when the initial parameter value is smaller
//	than the actual parameter value due to the limitation of
//	Design Compiler ability to handle parameters of Verilog
//	functions.  For the detailed information, please check
//	STARs 59352 and 59348.
//
//	This function is released for old users only for backward
//	compatibility.  New users should not use this function.
//	Instead, new users should use this part through component
//	instantiation.
//
//----------------------------------------------------------------------------

function DW_parity_gen;

  input par_type;
  input  [width-1:0] datain;
   
   begin 
     DW_parity_gen = DW_parity_odd({!par_type,datain});
   end    
endfunction // sim;  

function DW_parity_odd;
 
  // synopsys map_to_operator PAR_ODD_OP
  // synopsys return_port_name parity
 
  input  [width:0] datain;
 
   begin
     DW_parity_odd = ^datain;
   end
endfunction // sim;

