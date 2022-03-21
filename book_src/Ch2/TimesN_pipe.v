module TimesN_pipe(
  output reg [7:0] Times_x,
  input clk,
  input [7:0] X
);
  reg [7:0] Times_x1, Times_x2;
  reg [7:0] X1, X2;
  always @(posedge clk) begin
    // Pipeline stage 1
    X1 <= X; Times_x1 <= X;
    // Pipeline stage 2
    X2 <= X1;
    Times_x2 <= Times_x1 + X1;
    // Pipeline stage 3
    Times_x <= Times_x2 + X2;
  end
endmodule