reg [N-1:0]cnt;
always @(posedge clk)
  cnt<=cnt+'b1;
