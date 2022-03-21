module latch_N #(
    parameter N = 8
) (
    input clk,
    input[N-1:0] d,
    output[N-1:0] q
);
    
    assign q = clk ? d : q;

endmodule