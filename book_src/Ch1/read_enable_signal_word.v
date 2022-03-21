1  `timescale 1ns/1ps
2  `define LAST_TIME 3_000_000
3  `define DLY_1 1
4  
5  module read_enable_signal #(
6  parameter signal_WIDTH=10,
7  parameter FILENAME="./pat/dfai.dat"
8  )(
9  input clk,
10 input enable,
11 output reg signed [signal_WIDTH-1:0] signal_out
12 );
13 
14 integer signal_FILE;
15 reg signal_isNotFirstRise = 0;
16 reg signal_isSimulationEnd= 0;
17 reg signed [signal_WIDTH-1:0] tmp_sig_I;
18 
19 initial begin
20   signal_out=0;
21 #`DLY_1; signal_FILE = $fopen(FILENAME,"rb");
22   if (signal_FILE ==0) begin
23       $display("Error at opening file: %s",FILENAME);
24       $stop;
25   end else
26   	$display("Loading %s .........",FILENAME);
27 end
28 
29 always @(posedge clk) begin
30   signal_isNotFirstRise <=  #`DLY_1 1;
31 end
32 
33 //-- Apply Input Vectors -----
34 always@(posedge clk)
35   if(signal_isNotFirstRise) begin
36     if ($feof(signal_FILE) != 0) begin
37       signal_isSimulationEnd = 1;
38       #`LAST_TIME;
39       $finish(2);
40     end else if(enable) begin
41       if ($fscanf(signal_FILE, "%d\n", tmp_sig_I)<1) begin
42         signal_isSimulationEnd = 1;
43         #`LAST_TIME; $finish(2);
44       end else begin
45         `ifdef DATA_DEBUG
46           $display("Data is %d",tmp_sig_I);
47         `endif
48         signal_out <=  #`DLY_1 tmp_sig_I;
49       end
50     end
51   end
52 
53 endmodule
54 