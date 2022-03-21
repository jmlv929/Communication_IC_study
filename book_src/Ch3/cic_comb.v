module cic_comb #(parameter idw = 8, odw = 9, N = 15)(
    input   clk,
    input   reset_n,
    input   in_dv,
    input   signed [idw-1:0] data_in,
    output  reg signed [odw-1:0] data_out
);
reg signed [idw-1:0] data_reg[N-1:0];
integer i;
always @(posedge clk)
  if (!reset_n) begin
    for (i=0;i<N;i=i+1)
        data_reg[i] <= 'h0;
    data_out <= 'h0;
  end
  else if (in_dv) begin
    data_reg[0] <= data_in;
    for (i=1;i<N;i=i+1)
        data_reg[i] <= data_reg[i-1];
    data_out <= data_in - data_reg[N-1];
  end

endmodule
