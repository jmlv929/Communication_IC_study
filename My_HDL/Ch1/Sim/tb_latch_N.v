`timescale  1ns / 1ps 

module tb_latch_N;    

// latch_N Parameters 
parameter PERIOD = 10;
parameter N  = 8;

// latch_N Inputs
reg   clk                                  = 0 ;
reg   [N-1:0]  d                           = 0 ;

// latch_N Outputs
wire  [N-1:0]  q                           ;


initial
begin
    forever #(PERIOD/2)  clk=~clk;
end


latch_N #(
    .N ( N ))
 u_latch_N (
    .clk                     ( clk          ),
    .d                       ( d    [N-1:0] ),

    .q                       ( q    [N-1:0] )
);

initial
begin
    d = 2;
    # (PERIOD*20);

    d = 5;
    # (PERIOD*50);

    d = 8;
    # (PERIOD*20);

    d = 12;
    # (PERIOD*70);

    $finish;
end

endmodule