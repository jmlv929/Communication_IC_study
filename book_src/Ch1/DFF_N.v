module DFF_N #(parameter N=3)(
  input clk,
  input reset,
  input [N-1:0] D,
  output reg [N-1:0] Q
);
reg [N-1:0]d0;
reg [N-1:0]d1;
always@(posedge clk or negedge reset)
  if(!reset)begin
    d0 <= 0; //同步清 0，低电平有效
    d1 <= 0; //同步清 0，低电平有效
    Q  <= 0; //同步清 0，低电平有效
  end
  else begin
	d0 <= D;
	d1 <= d0;
	Q  <= d1;
  end

endmodule
