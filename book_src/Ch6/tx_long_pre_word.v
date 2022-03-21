01 `timescale 1ns / 1ps
02 module tx_long_pre(
03 input [5:0] index,  // 0 ~ 63
04 output reg [9:0] out_i,out_q
05 );
06 always @(index)
07   case (index)
08     6'd00: begin out_i = (  10'd160); out_q =  (     10'd0); end
09     6'd01: begin out_i = (   -10'd5); out_q =  (  -10'd123); end
10     6'd02: begin out_i = (   10'd41); out_q =  (  -10'd114); end
11     6'd03: begin out_i = (   10'd99); out_q =  (    10'd85); end
12     6'd04: begin out_i = (   10'd22); out_q =  (    10'd29); end
13     6'd05: begin out_i = (   10'd61); out_q =  (   -10'd90); end
14     6'd06: begin out_i = ( -10'd118); out_q =  (   -10'd57); end
15     6'd07: begin out_i = (  -10'd39); out_q =  (  -10'd109); end
16     6'd08: begin out_i = (  10'd100); out_q =  (   -10'd27); end
17     6'd09: begin out_i = (   10'd55); out_q =  (     10'd4); end
18     6'd10: begin out_i = (    10'd1); out_q =  (  -10'd118); end
19     6'd11: begin out_i = ( -10'd140); out_q =  (   -10'd49); end
20     6'd12: begin out_i = (   10'd25); out_q =  (   -10'd60); end
21     6'd13: begin out_i = (   10'd60); out_q =  (   -10'd15); end
22     6'd14: begin out_i = (  -10'd23); out_q =  (   10'd165); end
23     6'd15: begin out_i = (  10'd122); out_q =  (    -10'd4); end
24     6'd16: begin out_i = (   10'd64); out_q =  (   -10'd64); end
25     6'd17: begin out_i = (   10'd38); out_q =  (   10'd101); end
26     6'd18: begin out_i = (  -10'd59); out_q =  (    10'd40); end
27     6'd19: begin out_i = ( -10'd134); out_q =  (    10'd67); end
28     6'd20: begin out_i = (   10'd84); out_q =  (    10'd95); end
29     6'd21: begin out_i = (   10'd71); out_q =  (    10'd14); end
30     6'd22: begin out_i = (  -10'd62); out_q =  (    10'd83); end
31     6'd23: begin out_i = (  -10'd58); out_q =  (   -10'd22); end
32     6'd24: begin out_i = (  -10'd36); out_q =  (  -10'd155); end
33     6'd25: begin out_i = ( -10'd125); out_q =  (   -10'd17); end
34     6'd26: begin out_i = ( -10'd130); out_q =  (   -10'd21); end
35     6'd27: begin out_i = (   10'd77); out_q =  (   -10'd76); end
36     6'd28: begin out_i = (   -10'd3); out_q =  (    10'd55); end
37     6'd29: begin out_i = (  -10'd94); out_q =  (   10'd118); end
38     6'd30: begin out_i = (   10'd94); out_q =  (   10'd108); end
39     6'd31: begin out_i = (   10'd13); out_q =  (   10'd100); end
40     6'd32: begin out_i = ( -10'd160); out_q =  (     10'd0); end
41     6'd33: begin out_i = (   10'd13); out_q =  (  -10'd100); end
42     6'd34: begin out_i = (   10'd94); out_q =  (  -10'd108); end
43     6'd35: begin out_i = (  -10'd94); out_q =  (  -10'd118); end
44     6'd36: begin out_i = (   -10'd3); out_q =  (   -10'd55); end
45     6'd37: begin out_i = (   10'd77); out_q =  (    10'd76); end
46     6'd38: begin out_i = ( -10'd130); out_q =  (    10'd21); end
47     6'd39: begin out_i = ( -10'd125); out_q =  (    10'd17); end
48     6'd40: begin out_i = (  -10'd36); out_q =  (   10'd155); end
49     6'd41: begin out_i = (  -10'd58); out_q =  (    10'd22); end
50     6'd42: begin out_i = (  -10'd62); out_q =  (   -10'd83); end
51     6'd43: begin out_i = (   10'd71); out_q =  (   -10'd14); end
52     6'd44: begin out_i = (   10'd84); out_q =  (   -10'd95); end
53     6'd45: begin out_i = ( -10'd134); out_q =  (   -10'd67); end
54     6'd46: begin out_i = (  -10'd59); out_q =  (   -10'd40); end
55     6'd47: begin out_i = (   10'd38); out_q =  (  -10'd101); end
56     6'd48: begin out_i = (   10'd64); out_q =  (    10'd64); end
57     6'd49: begin out_i = (  10'd122); out_q =  (     10'd4); end
58     6'd50: begin out_i = (  -10'd23); out_q =  (  -10'd165); end
59     6'd51: begin out_i = (   10'd60); out_q =  (    10'd15); end
60     6'd52: begin out_i = (   10'd25); out_q =  (    10'd60); end
61     6'd53: begin out_i = ( -10'd140); out_q =  (    10'd49); end
62     6'd54: begin out_i = (    10'd1); out_q =  (   10'd118); end
63     6'd55: begin out_i = (   10'd55); out_q =  (    -10'd4); end
64     6'd56: begin out_i = (  10'd100); out_q =  (    10'd27); end
65     6'd57: begin out_i = (  -10'd39); out_q =  (   10'd109); end
66     6'd58: begin out_i = ( -10'd118); out_q =  (    10'd57); end
67     6'd59: begin out_i = (   10'd61); out_q =  (    10'd90); end
68     6'd60: begin out_i = (   10'd22); out_q =  (   -10'd29); end
69     6'd61: begin out_i = (   10'd99); out_q =  (   -10'd85); end
70     6'd62: begin out_i = (   10'd41); out_q =  (   10'd114); end
71     6'd63: begin out_i = (   -10'd5); out_q =  (   10'd123); end
72   endcase
73 
74 endmodule
75 