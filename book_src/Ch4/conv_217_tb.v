`define TIMESLICE 25
`define TESTSLICE 50

module conv_217_tb;

reg        masterclock ;
reg        halfclock   ;
reg        quadclock   ;
reg        testclock   ;
reg        rst_all     ;

initial
begin : masterclock_Generator
   masterclock = 0;
   forever
   #(`TIMESLICE/2) masterclock = !masterclock;
end

initial
begin : halfclock_Generator
   halfclock = 0;
   forever
   #(`TIMESLICE) halfclock = !halfclock;
end

initial
begin : quadclock_Generator
   quadclock = 0;
   forever
   #(`TIMESLICE*2) quadclock = !quadclock;
end

initial
begin : testclock_Generator
   testclock = 0;
   forever
   #(`TESTSLICE/2) testclock = !testclock;
end

initial
begin
  testclock=0;
  masterclock=0;
end


initial
begin
  rst_all=0;
  $display("reset valid");
  #(`TESTSLICE*16) rst_all=1;
  #(`TESTSLICE*16) rst_all=0;
  #(`TESTSLICE*16) rst_all=1;
end

`ifdef DEBUG
integer i;
initial
begin
  i=0;
  forever
  begin
    #1000_000;
    i=i+1;
    $display("\tNow advance to %d us....!",1000*i);
  end
end

initial
begin
  #150_500_000;
  $display("finish time is ",$time);
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
wire rst_n=rst_all;

reg syn_rst;

initial
begin
	syn_rst=0;
	@(posedge rst_all);
	#100;
	syn_rst=1'b1;
	repeat(10)@(posedge clk) syn_rst=1'b0;
	repeat(10)@(posedge clk) syn_rst=1'b1;
	forever
	begin
		repeat(4096*240-1)@(posedge clk) syn_rst=1'b0;
		repeat(1)@(posedge clk) syn_rst=1'b1;
	end
end

reg [7:0] rand;
always @(clk)
	rand=$random%255;


`ifndef dump_level
	`define dump_level 10
`endif
initial
begin
	
	#1;

  `ifdef VCS_DUMP
    $display("Start Recording Waveform in VPD format!");
    $vcdpluson();
    $vcdplustraceon;
  `endif
  
  `ifdef FSDB_DUMP
    $display("Start Recording Waveform in FSDB format!");
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(`dump_level);
    
    //$fsdbDumpMemOnChange
    //
  `endif
  
  `ifdef NC_DUMP
    //$recordsetup("version=1", "run=1","directory=.");
    $recordsetup;
    $recordvars;
  `endif
  
  `ifdef VCD_DUMP
    $display("Start Recording Waveform in VCD format!");
    $dumpfile("dump.vcd");
    $dumpvars(`dump_level);
  `endif
end


	wire ena=1;
	wire din;		// bit 0 is to be sent first
	wire[1:0] cout;
	
	assign din=rand[0];
	
	conv_217 u_conv_217(
	.clk   (clk   ), 
	.rst_n (rst_n ), 
	.ena   (ena   ), 
	.din 	 (din 	), 	// bit 0 is to be sent first
	.cout  (cout  ) 
	);
initial
begin
	//fork
	//  #20000 $finish(0);
	//  repeat(20000)@(posedge clk) $finish(0);
  //join   
   #2000000 $finish(0);  
end	

endmodule
