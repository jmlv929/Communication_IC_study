`timescale  1ns / 1ps

module tb_adder;     

// adder Parameters  
parameter PERIOD = 10;
parameter N  = 4;

// adder Inputs
reg   [N-1:0]  a                           = 0 ;
reg   [N-1:0]  b                           = 0 ;
reg   cin                                  = 0 ;

// adder Outputs
wire  cout                                 ;
wire  [N-1:0]  sum                         ;

adder #(
    .N ( N ))
 u_adder (
    .a                       ( a     [N-1:0] ),
    .b                       ( b     [N-1:0] ),
    .cin                     ( cin           ),

    .cout                    ( cout          ),
    .sum                     ( sum   [N-1:0] )
);

initial
begin
    a = 3;
    b = 4;

    # (10*PERIOD);

    a = 12;
    b = 9;
    # (10*PERIOD);


    $finish;
end

endmodule