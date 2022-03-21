`timescale  1ns / 1ps 

module tb_ALU;        

// ALU Parameters     
parameter PERIOD = 10;
parameter N  = 8;

// ALU Inputs
reg   [N-1:0]  opa                         = 0 ;
reg   [N-1:0]  opb                         = 0 ;
reg   [2:0]  opcode                        = 0 ;

// ALU Outputs
wire  [N-1:0] out                       ;


ALU #(
    .N ( N ))
 u_ALU (
    .opa                     ( opa             [N-1:0] ),
    .opb                     ( opb             [N-1:0] ),
    .opcode                  ( opcode          [2:0]   ),

    . out          ( out   [N-1:0]        )
);

initial
begin
    opa = 17;
    opb = 9;
    # (PERIOD*10);

    opcode = 2;
    # (PERIOD*10);

    opcode = 3;
    # (PERIOD*10);

    opcode = 4;
    # (PERIOD*10);




    $finish;
end

endmodule