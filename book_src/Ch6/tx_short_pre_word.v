01 `timescale 1ns/1ps
02 module tx_short_pre(
03  input[3:0]     index,//0~15
04  output reg[9:0]out_i,out_q
05 );
06 always@(index)
07   case(index)
08     4'd00: begin out_i= 10'd47   ; out_q= 10'd47   ; end
09     4'd01: begin out_i=-10'd136  ; out_q= 10'd2    ; end
10     4'd02: begin out_i=-10'd14   ; out_q=-10'd80   ; end
11     4'd03: begin out_i= 10'd146  ; out_q=-10'd13   ; end
12     4'd04: begin out_i= 10'd94   ; out_q= 10'd0    ; end
13     4'd05: begin out_i= 10'd146  ; out_q=-10'd13   ; end
14     4'd06: begin out_i=-10'd14   ; out_q=-10'd80   ; end
15     4'd07: begin out_i=-10'd136  ; out_q= 10'd2    ; end
16     4'd08: begin out_i= 10'd47   ; out_q= 10'd47   ; end
17     4'd09: begin out_i= 10'd2    ; out_q=-10'd136  ; end
18     4'd10: begin out_i=-10'd80   ; out_q=-10'd14   ; end
19     4'd11: begin out_i=-10'd13   ; out_q= 10'd146  ; end
20     4'd12: begin out_i= 10'd0    ; out_q= 10'd94   ; end
21     4'd13: begin out_i=-10'd13   ; out_q= 10'd146  ; end
22     4'd14: begin out_i=-10'd80   ; out_q=-10'd14   ; end
23     4'd15: begin out_i= 10'd2    ; out_q=-10'd136  ; end
24   endcase
25 endmodule
26 