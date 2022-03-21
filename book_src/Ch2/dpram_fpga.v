01 module dpram #(parameter ADDR_WIDTH=6 ,DATA_WIDTH=8) (
02   input [(DATA_WIDTH-1):0] data,
03   input [(ADDR_WIDTH-1):0] read_addr,
04   input [(ADDR_WIDTH-1):0] write_addr,
05   input we,
06   input clk,
07   output [(DATA_WIDTH-1):0] q  );
08   reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];
09 `ifdef DPRAM_OLD_DATA
10   reg [(DATA_WIDTH-1):0] q_out;
11   always @ (posedge clk)begin
12     if (we)
13       ram[write_addr] <= data;
14     q_out <= ram[read_addr]; // read old data!
15   end
16   assign q = q_out ;
17 `else
18   reg [(ADDR_WIDTH-1):0] read_addr_reg;
19   always @ (posedge clk)
20     if (we)ram[write_addr] <= data;
21   always @ (posedge clk)
22       read_addr_reg<=read_addr;
23   assign  q = ram[read_addr_reg]; // read old data!
24 `endif
25 `ifdef BLANK_RAM
26 integer i;
27 initial begin
28   for(i=0;i<2**ADDR_WIDTH;i=i+1) ram[i]=0;
29 end
30 `endif
31 endmodule