1 module synCordicAtan (clk, rst, en, x, y, atanOut); // { 
22 //省略了非关键性代码，完整内容请参考电子附件
23   assign negzo = -zo;
24   assign tmpx = -x;
25   assign tmpy = -y;//调用Cordic流水实现，由多个旋转模块串接组合而成
28 CordicSeq cs (.clk(clk),.rst(rst), .en(en), .xi(xi),  .yi(yi), .zi(zi), .xo(xo),.yo(yo),.zo(zo));
39   always @( posedge clk)
40   begin
41   if (rst==1’b1) 
42     begin
43     rcnt <= 0; //旋转次数
44     xi <= 0;
45     yi <= 0;
46     atanOut <= 0; //角度输出
47     for (i=0;i<depth;i=i+1)
48       quadrant[i] <= 2'b00;
49     end
50   else if (en) 
51     begin
52       if(rcnt!=depth)
53         rcnt <= rcnt+1; 
54 
55       if (x[bitWidth-1] == 0)
56         xi <= {x[bitWidth-1],x[bitWidth-1],x};
57       else
58         xi <= {tmpx[bitWidth-1],tmpx[bitWidth-1],tmpx};
59 
60       if (y[bitWidth-1] == 0)
61         yi <= {y[bitWidth-1],y[bitWidth-1],y};
62       else
63         yi <= {tmpy[bitWidth-1],tmpy[bitWidth-1],tmpy};
64 
65       quadrant[0][0] <= x[bitWidth-1];
66       quadrant[0][1] <= y[bitWidth-1];
67 
68       for (i=0;i<depth-1;i=i+1) 
69         quadrant[i+1] <= quadrant[i];
70 
71       if(rcnt==depth)
72         case (quadrant[depth-1]) 
73         2'b00 : atanOut <= zo;
74         2'b01 : atanOut <= {1'b1, tmpzero} - $unsigned(zo);
75         2'b10 : atanOut <= negzo; // use intermediate to force sizing
76         default : atanOut <= {1'b1, tmpzero} + $unsigned(zo);
77         endcase
78     end // if
79   end // always
80 
81 endmodule // }
