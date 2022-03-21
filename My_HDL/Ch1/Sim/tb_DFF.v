`timescale  1ns / 1ps 

module tb_DFF;        

// DFF Parameters     
parameter PERIOD = 10;
parameter N  = 1;

// DFF Inputs
reg   clk                                  = 0 ;
reg   aresetn                              = 0 ;
reg   [N-1:0]  D                           = 0 ;

// DFF Outputs
wire  [N-1:0]  D_rising_edge               ;
wire  [N-1:0]  D_falling_edge              ;


initial
begin
    forever #(PERIOD/2)  clk=~clk;
end

initial
begin
    #(PERIOD*2) aresetn  =  1;
end

DFF #(
    .N ( N ))
 u_DFF (
    .clk                     ( clk                     ),
    .aresetn                 ( aresetn                 ),
    .D                       ( D               [N-1:0] ),

    .D_rising_edge           ( D_rising_edge   [N-1:0] ),
    .D_falling_edge          ( D_falling_edge  [N-1:0] )
);

initial
begin
    D = 0;
    # (PERIOD*3);

    D = 1;
    # (PERIOD*10);

    D = 0;
    # (PERIOD*5);

    D = 1;
    # (PERIOD*20);

    $finish;
end

endmodule