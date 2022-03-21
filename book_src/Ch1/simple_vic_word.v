 module simple_vic#(parameter INT_NUM=6,parameter INT_WIDTH=8)(
   input clk,
   input rst_x,
   input [INT_NUM-1:0] int_source,
   input [INT_NUM-1:0] int_mask,
   input [INT_NUM-1:0] int_clr,
   output vic_int,
   output reg [INT_NUM-1:0] int_reg,
   output reg [INT_NUM-1:0] int_mask_reg
 );
 reg [INT_NUM-1:0] int_source_d0;
 reg [INT_NUM-1:0] int_source_d1;
 wire[INT_NUM-1:0] int_source_pulse;
 
 always @(posedge clk or negedge rst_x)
   if(!rst_x)begin
     int_source_d0<=0;
     int_source_d1<=0;
   end else begin
     int_source_d0<=int_source;
     int_source_d1<=int_source_d0;
   end
 
 assign int_source_pulse=(int_source_d0&~int_source_d1);
 wire vic_int_pulse  =|(int_source_pulse[INT_NUM-1:0] 
                      & int_mask[INT_NUM-1:0]);
 
 always @(posedge clk or negedge rst_x)
   if(!rst_x)
     int_reg<='d0;
   else if(|int_source_pulse)
     int_reg<=int_reg|int_source_pulse;
   else if(|int_clr) 
   	int_reg<=int_reg&(~int_clr);
 
 always @(posedge clk or negedge rst_x)
   if(!rst_x)
     int_mask_reg<='d0;
   else if(vic_int_pulse)
     int_mask_reg<=int_mask_reg | {int_source_pulse&int_mask};
   else if(|int_clr) 
   	int_mask_reg<=int_mask_reg&(~int_clr);
 
 reg [INT_WIDTH-1:0] clk_cnt;
 reg int_state;
 always @(posedge clk or negedge rst_x)
 	if(!rst_x)begin
 		clk_cnt<=0;
 		int_state<=1'b0;
 	end	else if(int_state==0)	begin
 		clk_cnt<=0;
 		if(vic_int_pulse)
 			int_state<=1'b1;
 	end	else begin 
 		if(~(|int_mask_reg))
 			int_state<=1'b0;
 		if(clk_cnt=={INT_WIDTH{1'b1}})
 			int_state<=0;
 		if(clk_cnt=={INT_WIDTH{1'b1}})
 			clk_cnt<=0;
 		else
 			clk_cnt<=clk_cnt+1'b1;
 	end
 // int duration!	
 assign vic_int=(INT_WIDTH==0) ? vic_int_pulse:int_state;
 endmodule
 