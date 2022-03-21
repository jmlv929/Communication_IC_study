module spram #(parameter ADDR_WIDTH=6 ,DATA_WIDTH=8)(
  input [(DATA_WIDTH-1):0] data,
	input [(ADDR_WIDTH-1):0] addr,
	input we, clk,
	output [(DATA_WIDTH-1):0] q
);
reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];
reg [ADDR_WIDTH-1:0] addr_reg;
always @ (posedge clk)begin
  if (we)
    ram[addr] <= data;

  addr_reg <= addr;
end
assign q = ram[addr_reg];
endmodule
