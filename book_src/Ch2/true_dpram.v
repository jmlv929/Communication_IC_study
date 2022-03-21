01 module true_dpram#(parameter DATA_WIDTH=8, parameter ADDR_WIDTH=6)(
02     input [(DATA_WIDTH-1):0] data_a,
03     input [(DATA_WIDTH-1):0] data_b,
04     input [(ADDR_WIDTH-1):0] addr_b,
05     input [(ADDR_WIDTH-1):0] addr_a,
06     input we_a,
07     input we_b,
08     input clk_a,
09     input clk_b,
10     output reg [(DATA_WIDTH-1):0] q_a,
11     output reg [(DATA_WIDTH-1):0] q_b
12 );
13 reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0]; // Declare the RAM variable
14 always @ (posedge clk_a)
15   if (we_a)begin
16       ram[addr_a] <= data_a;
17       q_a <= data_a;
18   end else
19     q_a <= ram[addr_a];
20
21 always @ (posedge clk_b)
22   if (we_b)begin
23     ram[addr_b] <= data_b;
24     q_b <= data_b;
25   end else
26     q_b <= ram[addr_b];
27
28 endmodule
29