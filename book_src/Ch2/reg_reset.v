 always @ (posedge HCLK)
   if(HRSET) begin
     RegFile1[REGFileWAddr]<=0;
     RegFile2[REGFileWAddr]<=0;
   end else if (REGFileWE) begin
     RegFile1[REGFileWAddr] <= RegFileDataIn;
     RegFile2[REGFileWAddr] <= RegFileDataIn;
   end


 module ram_reset(
   input  rst_n, clk, WEN,
   input [7:0] Addr,
   input [15:0] MEMIn,
   output reg [15:0] MEMOut
 );
 reg [15:0] MEM [255:0];

 always @(posedge clk or negedge rst_n)
   if(!rst_n)  // Òì²½¸´Î»Êä³ö
       MEMOut <= 0;
   else begin
      if(WEN) MEM[Addr] <= MEMIn;
      MEMOut <= MEM[Addr];
   end
 endmodule