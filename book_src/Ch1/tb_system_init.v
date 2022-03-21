/* *****************************************    init reset ************************* */
/* **********        1) Main clock and test clock set to 50MHz                    ** */
/* **********        2) Auto stop time is 10Us                                    ** */
/* **********                                                                     ** */
/* **********                                                                     ** */
/* **********                                                                     ** */
/* ***************************************** GS Core ******************************* */

// Create by Mr. Liqinghua
// rev.0.1 2006.07.17
// rev.0.2 2006.07.24

//`timescale 1ns/1ps

//`define TB_TOP mac_tb

`define TIMESLICE 25
`define TESTSLICE 50
///  Copy following in your testbench!
//
///  system_init  system_init();
///  waveform_record waveform_record();
///  
///  initial
///  begin
///    force clk       = system_init.masterclock   ;
///    force rst_x     = system_init.rst_all     ;
///  end
///  wire syn_rst = system_init.syn_rst;

module system_init;
reg        masterclock ;
reg        halfclock   ;
reg        quadclock   ;
reg        testclock   ;
reg        rst_all     ;

initial begin : masterclock_Generator
   masterclock = 0;
   forever #(`TIMESLICE/2) masterclock = !masterclock;
end

initial begin : halfclock_Generator
   halfclock = 0;
   forever #(`TIMESLICE) halfclock = !halfclock;
end

initial begin : quadclock_Generator
   quadclock = 0;
   forever #(`TIMESLICE*2) quadclock = !quadclock;
end

initial begin : testclock_Generator
   testclock = 0;
   forever #(`TESTSLICE/2) testclock = !testclock;
end

initial begin
  testclock=0;
  masterclock=0;
end

initial begin
  rst_all=0;
  $display("reset valid");
  #(`TESTSLICE*16) rst_all=1;
  #(`TESTSLICE*16) rst_all=0;
  #(`TESTSLICE*16) rst_all=1;
end

`ifdef DEBUG
integer i;
initial begin
  i=0;
  forever
  begin
    #1000_000;
    i=i+1;
    $display("\tNow advance to %d us....!",1000*i);
  end
end

initial begin
  #150_500_000;
  $finish_task;
  $finish(2);
end
`endif

task finish_task;
begin
  $display("finish time is ",$time);
  $finish(2);
end
endtask

wire clk=masterclock;
wire rst_x=rst_all;
reg syn_rst;
initial begin
	syn_rst=0;
	@(posedge rst_x);
	#100;
	syn_rst=1'b1;
	repeat(10)@(posedge clk) syn_rst=1'b0;
	repeat(10)@(posedge clk) syn_rst=1'b1;
	forever begin
		repeat(4096*240-1)@(posedge clk) syn_rst=1'b0;
		repeat(1)@(posedge clk) syn_rst=1'b1;
	end
end

endmodule

