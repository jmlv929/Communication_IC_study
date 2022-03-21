module sel #(
    parameter N = 2
) (
    input[N-1:0] opa,
    input[N-1:0] opb,
    input[N-1:0] opc,
    input[N-1:0] opd,
    output[N-1:0] result,
    input[1:0] sel
);
reg[N-1:0] mux_temp;

always@(*) begin
    case(sel)
    2'b00: mux_temp = opa;
    2'b01: mux_temp = opb;
    2'b10: mux_temp = opc;
    2'b11: mux_temp = opd;
    default:
        mux_temp = opa; 
    endcase
end
    assign result = mux_temp;
endmodule