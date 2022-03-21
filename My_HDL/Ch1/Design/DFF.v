module DFF #(
    parameter N = 1
) (
    input clk,
    input aresetn,
    input[N-1:0] D,
    output[N-1:0] D_rising_edge,
    output[N-1:0] D_falling_edge
);

reg[N-1:0] d0, d1, Q;

always@(posedge clk or negedge aresetn) begin
    if(!aresetn) begin
        d0 <= 0;
        d1 <= 0;
        Q <= 0;
    end
    else begin
        d0 <= D;
        d1 <= d0;
        Q <= d1;
    end
end

assign D_falling_edge = d0 & ~D;
assign D_rising_edge = ~d0 & D;

    
endmodule