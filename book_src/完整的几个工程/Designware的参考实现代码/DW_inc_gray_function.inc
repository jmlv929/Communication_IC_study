
//
////////////////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------------
//
// ABSTRACT:  Gray incrementer
//
// MODIFIED:
//
//-----------------------------------------------------------------------------

function [width-1:0] DWF_inc_gray;

  // synopsys map_to_operator INC_GRAY_STD_LOGIC_OP
  // synopsys return_port_name Z

  input [width-1 : 0] A;
  input               CI;

  reg [width : 0] ab_v;
  reg [width-1 : 0] zb_v;
  reg [width-1 : 0] z_v;

  integer i;

  begin

    // synopsys translate_off

     if ((^(A ^ A) !== 1'b0) || (^(CI ^ CI) !== 1'b0))
	z_v = {width{1'bx}};
     else begin
	ab_v[width] = 1'b0;
	for (i = width-1; i >= 0; i = i-1)
	   ab_v[i] = A[i] ^ ab_v[i+1];

	zb_v = ab_v[width-1 : 0] + CI;

	z_v = zb_v ^ (zb_v >> 1);
     end // else: !if((^(a ^ a) !== 1'b0))
     
    DWF_inc_gray = z_v;

    // synopsys translate_on

  end

endfunction

//-----------------------------------------------------------------------------
