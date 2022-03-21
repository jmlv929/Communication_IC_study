module bidir_data#(parameter N=8)(
  input en,
  input clk,
  inout[N-1:0] bidir
);
reg[N-1:0] temp;
assign bidir= en ? temp : 8'bz;
always@(posedge clk)
  if(en) temp=bidir;
  else   temp=temp+1;
endmodule