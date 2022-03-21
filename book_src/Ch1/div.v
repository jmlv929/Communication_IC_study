   module clk_div8(
     input clk,rst,
     output reg clk8
   );
     reg [2:0] count;
   
   always@(posedge clk)
     if (rst) begin
       clk8<=0;
       count<=0;
     end else begin
       if (count==7) count<=0;
         else count<=count+1;
   
       if (count<=3) clk8<=0;
         else clk8<=1;
   
     end
   endmodule
   