par_block ::=
    fork [: block_identifier] {block_item_declaration} {statement_or_null}
    join_keyword [: block_identifier]

join_keyword ::= join //verilog-2001
join_keyword ::= join | join_any | join_none //systemverilog

fork
  <task 1>
  <task 2>
  ....
  <task N>
  begin
    #watchdogtime disable <task N>
  end
join

fork
    begin
        $display("First Block\n");
        #20ns;
    end
    begin
        $display("Second Block\n");
        @eventA;
    end
join

`define TIMESLICE 25
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
  repeat(10)@(posedge clk);
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