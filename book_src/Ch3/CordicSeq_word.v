1 module CordicSeq (clk, rst, en, xi, yi, zi, xo, yo, zo); // {
17 
18   assign x[0] = xi;
19   assign y[0] = yi;
20   assign z[0] = zi;
22   generate
23     genvar i; //等效于depth个旋转串接组合起来，实际是流水线结构
24     for (i = 0; i < depth; i=i+1) 
25       begin : gen_seq
26       CordicRotator cr
33         (.clk(clk), .rst(rst), .en(en), .xi(x[i]), .yi(y[i]), .zi(z[i]), 
34           .xo(x[i+1]), .yo(y[i+1]), .zo(z[i+1]));
35       end 
36   endgenerate //gen_seq
37 
38   assign xo = x[depth];
39   assign yo = y[depth];
40   assign zo = z[depth];
42 endmodule // CordicSeq }
