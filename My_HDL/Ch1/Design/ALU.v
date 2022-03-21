module ALU #(
    parameter N = 8
) (
    input[N-1:0] opa,
    input[N-1:0] opb,
    input[2:0] opcode,
    output reg[N-1:0] out
);

localparam add = 3'd0,
minus = 3'd1,
band = 3'd2,
bor = 3'd3,
bnot = 3'd4;

always@(*) begin
    case(opcode)
        add: out= opa + opb;
        minus: out= opa - opb;
        band: out= opa & opb;
        bor: out = opa | opb;
        bnot: out = ~opa;
        default:
        out = 8'hx;
    endcase

end 



endmodule