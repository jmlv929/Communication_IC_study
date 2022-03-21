
////////////////////////////////////////////////////////////////////////////////

//---------------------------------------------------------------------------------
//
// ABSTRACT: Leading zero anticipator (LZA) for addition
//           The LZA - leading zero anticipation module works under
//           some basic conditions:
//           1. B is subtracted from A, and the result is expected to have 2
//              or more zeros. The case when only 1 zero happens, will require 
//              normalization.
//           2. The output is maximum when the vector should have all its bit 
//              positions shifted to the left during normalization. No 1-bit
//              is detected by the anticipator in the bit-vector
//           3. The estimation is not exact, and may have a value that is 1
//              less than the exact value. From the original algorithm, the
//              result may be 2 less than the exact, but a filtering process
//              was put in place to correct the error to only 1.
//
//              parameters      valid values 
//              ==========      ============
//              width          number of bits,  >1
//
//              Input ports     Size & Description
//              ===========     ==================
//              a               width bits
//                              First operand being added
//              b               width bits
//                              Second operand being added
//              Output ports    Size & Description
//              ===========     ==================
//              count           log2width bits
//                              predicted number of leading zeros
//              detect          1 bit
//                              indicates that the estimation is valid
//
// MODIFIED: 
//  jbd - adding verilog syntax requirements and modify i/o per rjk
//        modified original algorithm to use Alex's latest from DW_fp_addsub.
//
//---------------------------------------------------------------------------------



module DW_lza (


//--------------  ports
     a, 
     b,
     count

    // Embedded dc_shell script
    // _model_constraint_1
    // set_attribute current_design "enable_dp_opt" "TRUE" -type "boolean" -quiet
);


//----------------------------------------------------------------------------
// main module parameters

parameter width = 7;
`define log2width ((width>16)?((width>64)?((width>128)?8:7):((width>32)?6:5)):((width>4)?((width>8)?4:3):((width>2)?2:1)))

input [width-1:0] a;
input [width-1:0] b;
output [`log2width-1:0] count;

//
// Leading zero anticipator code for constrained operands A>B
// 
reg [width-1:0] a_lza;
reg [width-1:0] b_lza;
reg [width-1:0] g;  // greater than
reg [width:0] s; // smaller than 
reg [width-1:0] fr;
wire [`log2width:0] pos;
integer i;

always @ (a or b)
begin
  a_lza = a[width-1:0];
  b_lza = b;
  // greater than signals
    g = (a_lza &  ~b_lza);
  // smaller than signals
    s[width:1] = (~a_lza & b_lza);
    s[0] = 1'b0;
  // filter the results to estimate position of the leading one
    for (i = width-1; i >= 0; i=i-1) begin
        fr[i] = (g[i] & !(s[i])) | (s[i+1] & !s[i]);  
    end
end

// perform the detection of the leading 1 in the fr vector
// positions width to 0 of fr[] are used...
// When there is no detection, the max value is passed as position.
//   Instance of Leading one detector used  
//
  DW_lzd #(width) 
  U2 (.a (fr[width-1:0]), 
      .enc (pos),
      .dec () );


assign count = pos[`log2width-1:0];
`undef log2width
endmodule
