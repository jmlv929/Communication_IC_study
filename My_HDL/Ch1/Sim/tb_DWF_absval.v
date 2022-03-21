`timescale  1ns / 1ps   

module tb_DWF_absval;   

// DWF_absval Parameters
parameter PERIOD = 10;  
parameter N  = 8;

// DWF_absval Inputs
reg   [N-1:0]  opa                         = 0 ;

// DWF_absval Outputs
wire[N-1:0] opb                       ;



DWF_absval #(
    .N ( N ))
 u_DWF_absval (
    .opa                     ( opa             [N-1:0] ),

    .opb          (  opb  [N-1:0]        )
);

initial
begin

    opa = 7;
    # (PERIOD*8);

    opa = 8'b1000_0001;
    # (PERIOD*8);

    opa = 8'b1001_0001;
    # (PERIOD*12);

    opa = 8'b0001_0001;
    # (PERIOD*12);



    $finish;
end

endmodule