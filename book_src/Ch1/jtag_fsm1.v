01 module jtag_fsm1 (
02 input   clk,    // Internal clock
03 input   tdo_mux,// TDO before the negative edge flop
04 input   bypass, // JTAG instruction=BYPASS
05 input   tck,    // clock input
06 input   trst_n, // optional async reset active low
07 input   tms,    // Test Mode Select
08 input   tdi,    // Test Data In
09
10 output reg tdo, // Test Data Out
11 output reg tdo_enb,//Test Data Out tristate enable
12
13 output  tdi_r1,   // TDI flopped on TCK.
14 output  tck_rise, // tck rate clock enable
15 output  captureDR,// JTAG state=CAPTURE_DR
16 output  shiftDR,  // JTAG state=SHIFT_DR
17 output  updateDR, // JTAG state=UPDATE_DR
18 output  captureIR,// JTAG state=CAPTURE_IR
19 output  shiftIR,  // JTAG state=SHIFT_IR
20 output  updateIR
21 );
22 reg     tck_r1,tck_r2,tck_r3;
23 reg     tdi_f_local; //  local version
24 wire    tdo_enb_nxt; //  D input to TDO_ENB flop
25 wire    tdo_nxt; //  D input to TDO flop
26 wire    itck_rise;
27 wire    tck_fall;
28
29 reg     [3:0] state; //  current state
30 wire    a,b,c,d,a_nxt,b_nxt,c_nxt,d_nxt;
31 assign {d,c,b,a} = state[3:0]; //a:0,b:1,c:2,d:3
32
33 assign a_nxt=(~tms& ~c & a)|(tms &~b)|(tms & ~a)|(tms& d & c);
34 assign b_nxt=(~tms& b & ~a)|(~tms&~c)|(~tms & ~d & b)|(~tms & ~d & ~a)|(tms & c & ~b)|(tms & d & c & a);
35 assign c_nxt=(c & ~b)|(c&a)|(tms &~b);
36 assign d_nxt=(d & ~c)|(d&b)|(~tms&c&~b)|(~d & c & ~b &~a);
37
38 assign tdo_enb_nxt = state == 4'b0010 | state == 4'b1010 ? 1'b1: 1'b0;
39 assign captureIR = state == 4'b1110 ? 1'b1:1'b0;
40 assign shiftIR = state == 4'b1010 ? 1'b1:1'b0;
41 assign updateIR = state == 4'b1101 ? 1'b1:1'b0;
42 assign captureDR = state == 4'b0110 ? 1'b1:1'b0;
43 assign shiftDR = state == 4'b0010 ? 1'b1:1'b0;
44 assign updateDR = state == 4'b0101 ? 1'b1:1'b0;
45 assign tdo_nxt = (bypass ==1'b1&state == 4'b0010)?tdi_f_local:tdo_mux;
46 assign tdi_r1 = tdi_f_local;
47
48 always @(posedge clk) begin:rtck_proc
49   tck_r3 <= tck_r2;
50   tck_r2 <= tck_r1;  //synchronizers for edge detection
51   tck_r1 <= tck;
52 end
53 assign tck_rise = itck_rise;
54 assign itck_rise = tck_r2  &  ~tck_r3;
55 assign tck_fall = ~tck_r2  &  tck_r3;
56
57 always @(posedge clk)
58   if (trst_n == 1'b0)
59      state <= 4'b1111;
60   else if (itck_rise == 1'b1)begin
61      state <= {d_nxt, c_nxt, b_nxt, a_nxt};
62   end
63
64 always @(posedge clk)
65    if (trst_n == 1'b0)
66       tdi_f_local <= 1'b0;
67    else if (itck_rise == 1'b1 ) begin
68       tdi_f_local <= tdi;
69    end
70
71 always @(posedge clk)
72   if (trst_n == 1'b0)begin
73       tdo <= 1'b0;
74       tdo_enb <= 1'b0;
75    end
76    else if (tck_fall == 1'b1 ) begin
77       tdo <= tdo_nxt;
78       tdo_enb <= tdo_enb_nxt;
79    end
80
81 endmodule // module vjtag
82
83