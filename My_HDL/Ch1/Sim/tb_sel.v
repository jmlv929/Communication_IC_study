`timescale  1ns / 1ps

module tb_sel;

// sel Parameters
parameter PERIOD = 10;
parameter N  = 2;

// sel Inputs
reg   [N-1:0]  opa                         = 0 ;
reg   [N-1:0]  opb                         = 0 ;
reg   [N-1:0]  opc                         = 0 ;
reg   [N-1:0]  opd                         = 0 ;
reg   [1:0]  sel                           = 0 ;

// sel Outputs
wire  [N-1:0]  result                      ;


sel #(
    .N ( N ))
 u_sel (
    .opa                     ( opa     [N-1:0] ),
    .opb                     ( opb     [N-1:0] ),
    .opc                     ( opc     [N-1:0] ),
    .opd                     ( opd     [N-1:0] ),
    .sel                     ( sel     [1:0]   ),

    .result                  ( result  [N-1:0] )
);

initial
begin
    opa = 0;
    opb = 1;
    opc = 2;
    opd = 3;

    sel = 0;
    # (PERIOD*5)


    sel = 2;
    # (PERIOD*10)

    $finish;
end

endmodule