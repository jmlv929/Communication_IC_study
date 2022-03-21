1 module synCordicSinCos (clk, rst, en, inp, sinout, cosout); // {
18 parameter signed [29:0] xif=128'b0010_0110_1101_1101_0011_1011_0110_10;
23   parameter signed [bitWidth-1:0] xi = xif[29:30-bitWidth];//正弦比例k值
24   parameter signed [bitWidth-1:0] yi = 0;
25   wire signed [angBitWidth-2:0] zo;
27 
28   assign argi = inp[angBitWidth-3:0];//四个象限，所以去除高2bit，后面再恢复
29   assign tmpzero = 0;
31 CordicSeq cs (.clk(clk),.rst(rst),.en(en),.xi(xi),.yi(yi),.zi(arg),
xo(cosarg),.yo(sinarg),.zo(zo));
41   assign sel = inp[angBitWidth-1:angBitWidth-2];
42 
43   always @( posedge clk) //csc
54     if (en) begin
56       if(rcnt!=depth+1)
57         rcnt <= rcnt+1;
58       
59       case(sel)
60       2'b00: begin
62         arg <= {1'b0,argi};
63         csgn[0] <= 0;
64         ssgn[0] <= 0;
65         end
66       2'b01: begin // 校正到第二象限符号，因为现在求的是第一象限角度。
68         arg <= {1'b1,tmpzero} - argi;
69         csgn[0] <= 1;
70         if (argi == 0) 
71           ssgn[0] <= 1;
72         else 
73           ssgn[0] <= 0;
74         end 
75       2'b10: begin // 校正到第三象限符号，因为现在求的是第一象限角度。
77         arg <= {1'b0,argi};
78         csgn[0] <= 1;
79         ssgn[0] <= 1;
80         end
81       default: begin // 校正到第四象限符号，因为现在求的是第一象限角度。
83         arg <= {1'b1,tmpzero} - argi;
84         csgn[0] <= 0;
85         if (argi == 0) 
86           ssgn[0] <= 0;
87         else 
88           ssgn[0] <= 1;
89         end
90       endcase
92       // propagate the signs
93       for (i=0;i<depth;i=i+1)
94         begin
95         csgn[i+1] <= csgn[i];
96         ssgn[i+1] <= ssgn[i];
97         end // for
99       // record the output
100       if(rcnt==depth+1)
101       begin
102       if (csgn[depth]==0) 
103         cosout <= cosarg;
104       else 
105         cosout <= -cosarg;
107       if (ssgn[depth]==0) 
108         sinout <= sinarg;
109       else 
110         sinout <= -sinarg;
111       end
112       else
113       begin
114         cosout <= 0;
115         sinout <= 0;
116       end
117     end // if (rst)...else if (en)
119   end // always @(posedge clk)
121 endmodule // }
