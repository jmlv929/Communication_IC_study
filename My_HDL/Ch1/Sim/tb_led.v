`timescale  1ns / 1ps

module tb_led;

// led Parameters
parameter PERIOD   = 10           ;
parameter N        = 6            ;
parameter TIMEOUT  = 32'h05;

// led Inputs
reg   clk                                  = 0 ;
reg   reset                                = 0 ;

// led Outputs
wire [N-1:0] led                       ;


initial
begin
    forever #(PERIOD/2)  clk=~clk;
end

initial
begin
reset = 1;
    #(PERIOD*2) reset  =  0;
end

led #(
    .N       ( N       ),
    .TIMEOUT ( TIMEOUT ))
 u_led (
    .clk                     ( clk              ),
    .reset                   ( reset            ),

    .led          ( led   )
);

initial
begin

# (PERIOD*100)

    $finish;
end

endmodule