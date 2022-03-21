module led #(
    parameter N = 6,
    parameter TIMEOUT = 32'hffff_ffff
) (
    input clk,
    input reset,
    output reg[N-1:0] led
);

reg[31:0] cnt;

always@(posedge clk) begin
    if(reset)
        cnt <= 0;
    else if(cnt == TIMEOUT)
        cnt <= 0;
    else
        cnt <= cnt + 1'b1;
end


always@(posedge clk) begin
    if(reset)
        led <= 1;
    else begin
        if(led == 0)
            led <= 1;
        else if(cnt == TIMEOUT)
            led <= led << 1;
        else
            led <= led;
    end
end

endmodule
