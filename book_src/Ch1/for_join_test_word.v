`define TIMESLICE 20
module fork_join_test(output reg a, b, c, d, e, f);
reg clk=0;
initial begin : clock_Generator
  forever #(`TIMESLICE) clk = !clk;
end

initial $monitor($time,,,"a=%b,b=%b,c=%b,d=%b,e=%b,f=%b",a,b,c,d,e,f);
initial begin
  a = 0;
  b = 0;
  c = 0;
  d = 0;
  e = 0;
  f = 0;
  repeat(5)@(posedge clk);
  $finish(2);
end

always @(posedge clk)
fork
  #2 a = ~a;
  #2 b = ~b;
  begin
    #2 c = ~a;
    #2 d = ~b;
    #2 e = ~c;
  end
  #2 f = ~e;
join

endmodule
