`define TIMES 3
module TimesN(
  output reg [7:0] Times_x, 
  output	finished,
  input	[7:0] X,
  input	clk, start
);
reg	[7:0] times;
assign finished = (times == 0); 

always@(posedge clk) 
  if(start) begin 
    Times_x <= X; 
    times <= `TIMES; //`TIMES=3，为宏定义
  end else if(!finished) begin
    times <= times - 1; 
    Times_x <= Times_x + X;
  end
endmodule
