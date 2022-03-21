module shift_reg #(parameter taps=8,parameter width=16)(
  input clk,
  input rst_n,
  input [width-1:0] d_in,
  output[width-1:0] d_out
);
 
generate 
genvar i;
for(i=0; i<width; i=i+1) begin:shift_reg
  reg  [taps-1:0] r_reg;
  wire [taps-1:0] r_next;
  always@(posedge clk, negedge rst_n)
    if(!rst_n)
      r_reg <= 0;
    else
      r_reg <= r_next;
   
  assign r_next = {d_in[i], r_reg[taps-1:1]};
  assign d_out[i] = r_reg[0];
end
endgenerate

endmodule