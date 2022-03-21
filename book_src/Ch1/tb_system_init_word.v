1  `define TIMESLICE 25
2  `define TESTSLICE 50
3  ///  Copy following in your testbench!
4  //
5  ///  system_init  system_init();
6  ///  waveform_record waveform_record();
7  ///  
8  ///  initial
9  ///  begin
10 ///    force clk       = system_init.masterclock   ;
11 ///    force rst_x     = system_init.rst_all     ;
12 ///  end
13 ///  wire syn_rst = system_init.syn_rst;
14 
15 module system_init;
16 reg        masterclock ;
17 reg        halfclock   ;
18 reg        quadclock   ;
19 reg        testclock   ;
20 reg        rst_all     ;
21 
22 initial begin : masterclock_Generator
23    masterclock = 0;
24    forever #(`TIMESLICE/2) masterclock = !masterclock;
25 end
26 
27 initial begin : halfclock_Generator
28    halfclock = 0;
29    forever #(`TIMESLICE) halfclock = !halfclock;
30 end
31 
32 initial begin : quadclock_Generator
33    quadclock = 0;
34    forever #(`TIMESLICE*2) quadclock = !quadclock;
35 end
36 
37 initial begin : testclock_Generator
38    testclock = 0;
39    forever #(`TESTSLICE/2) testclock = !testclock;
40 end
41 
42 initial begin
43   testclock=0;
44   masterclock=0;
45 end
46 
47 initial begin
48   rst_all=0;
49   $display("reset valid");
50   #(`TESTSLICE*16) rst_all=1;
51   #(`TESTSLICE*16) rst_all=0;
52   #(`TESTSLICE*16) rst_all=1;
53 end
54 
55 `ifdef DEBUG
56 integer i;
57 initial begin
58   i=0;
59   forever
60   begin
61     #1000_000;
62     i=i+1;
63     $display("\tNow advance to %d us....!",1000*i);
64   end
65 end
66 
67 initial begin
68   #150_500_000;
69   $finish_task;
70   $finish(2);
71 end
72 `endif
73 
74 task finish_task;
75 begin
76   $display("finish time is ",$time);
77   $finish(2);
78 end
79 endtask
80 
81 wire clk=masterclock;
82 wire rst_x=rst_all;
83 reg syn_rst;
84 initial begin
85 	syn_rst=0;
86 	@(posedge rst_x);
87 	#100;
88 	syn_rst=1'b1;
89 	repeat(10)@(posedge clk) syn_rst=1'b0;
90 	repeat(10)@(posedge clk) syn_rst=1'b1;
91 	forever begin
92 		repeat(4096*240-1)@(posedge clk) syn_rst=1'b0;
93 		repeat(1)@(posedge clk) syn_rst=1'b1;
94 	end
95 end
96 
97 endmodule
98 