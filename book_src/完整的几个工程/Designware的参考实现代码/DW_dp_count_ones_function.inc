
//
////////////////////////////////////////////////////////////////////////////////


// parameters: width


// parameter lower bound check
`define param_lower_check(func_name, param_name, param_value, lower_bound) \
  if (! (lower_bound <= param_value)) \
    $display ("\nError:  Invalid value for parameter '", param_name, \
              "' in function '", func_name, "' (= ", param_value, \
              ", lower bound is ", lower_bound, ")")


// ----------------------------------------------------------------------------
// DWF_dp_count_ones: Count-ones functions
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// count-ones (unsigned)
function [width-1 : 0] DWF_dp_count_ones;

  input [width-1 : 0] a;

  reg [width-1 : 0] z;

  integer i;

  begin

    // synopsys translate_off

    // parameter range check
    `param_lower_check("DWF_dp_count_ones", "width", width, 1);

    // count all ones in input vector
    z = 0;
    for (i = 0; i < width; i = i+1) begin
      if (a[i] == 1'b1)
        z = z + 1;
    end

    DWF_dp_count_ones = z;

    // synopsys translate_on

  end

endfunction


// ----------------------------------------------------------------------------
