01 module LUT_2bit_inc(
02   input     [0:1]  in, //in : input number, 2 bits
03   output reg[0:1] out,//out: results as a + 1, 2 bits
04   output reg c        //c  : carry flag, 1 bit
05 );
06 always @(in)
07   case (in) //    %results depends on the value of a
08     2'b00: begin out<= 2'b01; c<= 1'b0;end //in= 0, out= 1, c= 0
09     2'b01: begin out<= 2'b10; c<= 1'b0;end //in= 1, out= 2, c= 0
10     2'b10: begin out<= 2'b11; c<= 1'b0;end //in= 2, out= 3, c= 0
11     2'b11: begin out<= 2'b00; c<= 1'b1;end //in= 3, out= 0, c= 1
12   endcase
13 endmodule
14