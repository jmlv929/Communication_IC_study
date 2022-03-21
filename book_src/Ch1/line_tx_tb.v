module line_tx_tb  ; 

  wire    o_tx_data   ; 
   wire    o_tx_int   ; 
 
  reg    i_clk_tx   ; 
  reg    i_rst_n   ; 
  reg  [7:0]  i_data   ; 
  reg    i_clk   ; 
  reg 	[1:0]i_verify_mode;
  reg    i_start_n   ; 
  line_tx  
   DUT  ( 
       .o_tx_int (o_tx_int ) ,
      .i_clk_tx (i_clk_tx ) ,
      .i_rst_n (i_rst_n ) ,
	  .i_verify_mode(i_verify_mode),
      .i_data (i_data ) ,
      .i_clk (i_clk ) ,
      .o_tx_data (o_tx_data ) ,
      .i_start_n (i_start_n ) ); 
	  
	  
	initial begin
		i_rst_n = 0;
		i_clk = 0;
		i_clk_tx = 0;
		i_start_n = 1;
		i_verify_mode = 'bz;
		i_data = 'bz;
		#50
			i_data = 8'd125 ;
			i_verify_mode = 2'b11;
		#400
			i_rst_n = 1 ;
		#50
			i_start_n = 0;
		#100
			i_start_n = 1;
			i_data = 8'bz;
	end
	
	//event newtrans;
	//always @(posedge i_clk)	if(o_tx_int) -> newtrans;
	
	//always @(newtrans) begin
	always @ (posedge o_tx_int) begin
		#400 ;
		i_data = {$random} % 256 ;
		i_verify_mode  = {$random} % 4;
		#50 
			i_start_n = 0;
		#100
			i_start_n = 1;
			i_data = 8'bz;
	end
	
	
	always #50 i_clk = ~ i_clk;
	always begin
		#400 i_clk_tx = 1;
		#100 i_clk_tx = 0;
	end
	
endmodule

