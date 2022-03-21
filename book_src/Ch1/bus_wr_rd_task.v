`define TIMESLICE 25
module bus_wr_rd_test();
reg clk,rd,wr,ce;
reg [7:0]  addr,data_wr,data_rd;
reg [7:0]  read_data;
// Clock Generator
initial begin : clock_Generator
   clk = 0;
   forever #(`TIMESLICE) clk = !clk;
end

initial begin
  read_data = 0;
  rd = 0;
  wr = 0;
  ce = 0;
  addr = 0;
  data_wr = 0;
  data_rd = 0;
  // Call the write and read tasks here
  #1 cpu_write(8'h55,8'hF0);
  #1 cpu_write(8'hAA,8'h0F);
  #1 cpu_write(8'hBB,8'hCC);
  #1 cpu_read (8'h55,read_data);
  #1 cpu_read (8'hAA,read_data);
  #1 cpu_read (8'hBB,read_data);
  repeat(10)@(posedge clk);
  $finish(2);
end

// CPU Read Task
task cpu_read;
input [7:0]  address;
output [7:0] data;
begin
  $display ("%g CPU Read @address : %h", $time, address);
  $display ("%g  -> Driving CE, RD and ADDRESS on to bus", $time);
  @ (posedge clk);
  addr = address; ce = 1; rd = 1;
  @ (negedge clk);
  data = data_rd;
  @ (posedge clk);
  addr = 0; ce = 0;  rd = 0;
  $display ("%g CPU Read  data              : %h", $time, data);
  $display ("======================");
end
endtask
// CU Write Task
task cpu_write;
input [7:0]  address;
input [7:0] data;
begin
  $display ("%g CPU Write @address : %h Data : %h",$time, address,data);
  $display ("%g -> Driving CE, WR, WR data and ADDRESS on to bus",$time);
  @ (posedge clk);
  addr = address; ce = 1; wr = 1;
  data_wr = data;
  @ (posedge clk);
  addr = 0;  ce = 0;  wr = 0;
  $display ("======================");
end
endtask

// Memory model for checking tasks
reg [7:0] mem [0:255];
always @ (addr or ce or rd or wr or data_wr)
if (ce) begin
  if (wr) begin
    mem[addr] = data_wr;
  end
  if (rd) begin
    data_rd = mem[addr];
  end
end

endmodule
