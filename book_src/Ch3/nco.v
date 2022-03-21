module NCO #( parameter DATA_WIDTH=28)(
  input                   clk,
  input                   rst_n,
  input                   ena,
  input  [DATA_WIDTH-1:0] fre_chtr,
  input  [DATA_WIDTH-1:0] pha_chtr,
  output [DATA_WIDTH-1:0] sin_out,
  output [DATA_WIDTH-1:0] cos_out,
  output [DATA_WIDTH-1:0] eps_out
);  
reg [DATA_WIDTH-1:0] phase_in;
reg [DATA_WIDTH-1:0] fre_chtr_reg;

always@(posedge clk or negedge rst_n)
  if(!rst_n)
    fre_chtr_reg<=28'd0;
  else if(ena)
    fre_chtr_reg<=fre_chtr+fre_chtr_reg;   

always@(posedge clk or negedge rst_n)
  if(!rst_n)
    phase_in<=28'd0;
  else if(ena)
    phase_in<=pha_chtr+fre_chtr_reg;   
  
sincos u_sincos(.clk(clk),.rst_n(rst_n),.ena(ena),.phase_in(phase_in),.sin_out(sin_out),.cos_out(cos_out),.eps(eps_out));           
endmodule 
