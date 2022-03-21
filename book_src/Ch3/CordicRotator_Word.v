1 module CordicRotator (clk, rst, en, xi, yi, zi, xo, yo, zo); //省略信号声明
97    wire signed [bitWidth-1:0] sx,sy;
99    assign sx = xi >>> smi; //smi为常量参数，实际实现时为连线
100   assign sy = yi >>> smi; //
103   wire signed [angFracWidth-1:0] at;
105   assign at = appr(0); //具备近似值修正的反正切表，根据smi查表
106 
107   always @(posedge clk)
109     if (rst==1’b1)begin
111       xo <= 0;
112       yo <= 0;
113       zo <= 0;
114     end
115     else if (en)begin
119       if (rotMode==1) 
120         if (zi >= 0)begin 
122           xo <= xi - sy;
123           yo <= yi + sx;
124           zo <= zi - at;
125         end else begin
128           xo <= xi + sy;
129           yo <= yi - sx;
130           zo <= zi + at;
131         end // if (zi...
132       else
133         if (yi >=0) begin  
135           xo <= xi + sy;
136           yo <= yi - sx;
137           zo <= zi + at;
138         end else begin
141           xo <= xi - sy;
142           yo <= yi + sx;
143           zo <= zi - at;
144         end // if(yi...
145    end // if(en)
148 endmodule // CordicRotator
