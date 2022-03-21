
//
////////////////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------------
//
// ABSTRACT:  Gray to Binary Converter
//
// MODIFIED:
//
//-----------------------------------------------------------------------------

function [width-1:0] DWF_gray2bin;

  // synopsys map_to_operator GRAY2BIN_STD_LOGIC_OP
  // synopsys return_port_name B

  input [width-1 : 0] G;

  reg [width : 0] b_v;

    integer i;

  begin

    // synopsys translate_off

     if ((^(G ^ G) !== 1'b0))
	b_v =  {width{1'bx}};
     else begin
	b_v[width] = 1'b0;
	for (i = width-1; i >= 0; i = i-1)
	   b_v[i] = G[i] ^ b_v[i+1];
     end // else: !if((^(G ^ G) !== 1'b0))
     
    DWF_gray2bin = b_v[width-1 : 0];

    // synopsys translate_on

  end

endfunction

//-----------------------------------------------------------------------------
