18 module multi_seq_full #(parameter MUL_WIDTH=4)(
19   input  clk,
20   input [MUL_WIDTH-1:0]  x,
21   input [MUL_WIDTH-1:0]  y,
22   output reg [2*MUL_WIDTH-1:0]  result);
23 
24 localparam MUL_STEP=`log_floor(MUL_WIDTH);//log宏定义
25 localparam MULT_INIT= 0,  MULT_SEQ= 1,MULT_RESULT= 2;
26 
27 reg  [MUL_STEP-1:0] count=0;
28 reg  [1:0]  state  = 0;
29 reg  [2*MUL_WIDTH-1:0] P,  T;
30 reg  [MUL_WIDTH-1:0]  y_reg;
31 
32 always  @(posedge  clk) //reset is ommit!
33 begin
34  case  (state)
35    MULT_INIT: begin
36      count <= 0;  P <= 0; y_reg  <=  y;
37      T <= {{MUL_WIDTH{1'b0}},x};
38      state  <=  MULT_SEQ;
39    end
40    
41    MULT_SEQ:  begin
42      if(count == MUL_WIDTH-1) state  <=  MULT_RESULT;
43      else begin
44          if(y_reg[0]  ==  1'b1)  P<= P + T;
45          else  P  <=  P;
46          
47          y_reg  <=  y_reg  >>  1;
48          T  <=  T  <<  1;
49          count  <=  count  +  1;
50          state  <=  MULT_SEQ;
51      end
52    end
53 
54    MULT_RESULT:  begin result<= P; state <=MULT_INIT; end
55      default: state  <=  MULT_INIT ;
56  endcase
57 end
58 endmodule

DW02_mult #(9,9)U_Comn( .A(b_b),.B(cossin),.TC(1'B1),.PRODUCT(common));
DW02_mult #(9,9)U_i   ( .A(cos),.B(ab    ),.TC(1'B1),.PRODUCT(mul_i ));
DW02_mult #(9,9)U_q   ( .A(sin),.B(a_b   ),.TC(1'B1),.PRODUCT(mul_q ));

