module RanGen(
  input      rst_n,  // reset signal
  input      clk,    //clock signal
  input      load,   //load seed to rand_num
  input [7:0]rnd_seed,   
  output[7:0]lsfr_rand //random number output
);
reg[7:0]lsfr;
assign lsfr_rand=lsfr;

always@(posedge clk or negedge rst_n)
  if(!rst_n)
    lsfr  <=8'b1111_1111;
  else if(load)
    lsfr <=rnd_seed;  
  else begin
    lsfr[0] <= lsfr[7];
    lsfr[1] <= lsfr[0];
    lsfr[2] <= lsfr[1];
    lsfr[3] <= lsfr[2];
    lsfr[4] <= lsfr[3]^lsfr[7];
    lsfr[5] <= lsfr[4]^lsfr[7];
    lsfr[6] <= lsfr[5]^lsfr[7];
    lsfr[7] <= lsfr[6];
  end
endmodule