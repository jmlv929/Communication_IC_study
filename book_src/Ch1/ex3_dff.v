module DFF(
	input D,
	input CLK,
	output reg Q
);

always@(posedge CLK)
  Q <= D;

endmodule
