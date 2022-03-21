
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
// DWF_dp_absval: Absolute value functions
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// absolute value (signed)
function signed [width-1 : 0] DWF_dp_absval;

  input signed [width-1 : 0] a;

  reg signed [width-1 : 0] z;

  begin

    // synopsys translate_off

    // parameter range check
    `param_lower_check("DWF_dp_absval", "width", width, 1);

    // complement if negative
    if (a >= 0)
      z = a;
    else
      z = -a;

    DWF_dp_absval = z;

    // synopsys translate_on

  end

endfunction


// ----------------------------------------------------------------------------
