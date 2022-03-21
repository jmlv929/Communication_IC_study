

//-----------------------------------------------------------------------------
//
// ABSTRACT:  Product Sum (1 product with an added vector)
//
//
// MODIFIED:
//
//
//------------------------------------------------------------------------------

module DW02_prod_sum( A, B, TC, SUM );


// parameters
parameter A_width = 4;
parameter B_width = 5;
parameter num_inputs = 4;
parameter SUM_width = 12;

localparam int_acc_width = (SUM_width < (A_width+B_width+2))? A_width+B_width+2 : SUM_width;

//-----------------------------------------------------------------------------
// ports
input [num_inputs * A_width-1 : 0]	A;
input [num_inputs * B_width-1 : 0]	B;
input			TC;
output [SUM_width-1:0]	SUM;

reg    [SUM_width-1:0]	SUM;


  always @ (A or B or TC) begin : PROC_sum_prods
    reg signed [A_width : 0]		a_int;
    reg signed [B_width : 0]		b_int;
    reg signed [int_acc_width-1 : 0]	sum_int;
    integer i, j, k, l;

    j = 0;
    k = 0;
    sum_int = {int_acc_width{1'b0}};

    for (i=0 ; i < num_inputs ; i=i+1) begin
      a_int[A_width] = (TC == 1'b0)?  1'b0 : A[j+A_width-1];
      for (l=0 ; l < A_width ; l=l+1) begin
        a_int[l] = A[j+l];
      end

      b_int[B_width] = (TC == 1'b0)?  1'b0 : B[k+B_width-1];
      for (l=0 ; l < B_width ; l=l+1) begin
        b_int[l] = B[k+l];
      end

      sum_int = sum_int + (a_int * b_int);

      j = j + A_width;
      k = k + B_width;
    end

    SUM = sum_int[SUM_width-1 : 0];
  end

endmodule
