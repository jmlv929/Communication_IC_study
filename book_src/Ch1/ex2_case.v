module mux #(parameter N=2)(
input [N-1:0] a, 
input [N-1:0] b, 
input [N-1:0] c, 
input [N-1:0] d, 
input [1:0] sel, 
output[N-1:0] mux_out 
);
reg [N-1:0] mux_temp;
assign mux_out=mux_temp;

//always_comb 
always @ (a or b or c or d or sel) 
case (sel) 
  0 : mux_temp = a; 
  1 : mux_temp = b; 
  2 : mux_temp = c; 
  3 : mux_temp = d; 
  default : $display("Error with sel signal"); 
endcase 
    
endmodule
