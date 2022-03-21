   module dpram #(parameter ADDR_WIDTH=6 ,DATA_WIDTH=8) (
   input [(DATA_WIDTH-1):0] data,
   input [(ADDR_WIDTH-1):0] read_addr,
   input [(ADDR_WIDTH-1):0] write_addr,
   input we,
   input clk,
   output [(DATA_WIDTH-1):0] q  
   );
   reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];
   reg [(DATA_WIDTH-1):0] q_out;
   always @ (posedge clk) begin
     if (we)
        ram[write_addr] <= data;
     q_out <= ram[read_addr]; // read old data!
   end
   assign q = q_out ;
   endmodule

