module  PowerN_comb2 (
   output    [7:0]   Times_x,
   input     [7:0]   X
);
   wire      [7:0]   Times_x1,Times_x2;
   assign  Times_x1  = X;
   assign  Times_x2  = Times_x1*X;
   assign  Times_x4  = Times_x2*Times_x2;
endmodule
