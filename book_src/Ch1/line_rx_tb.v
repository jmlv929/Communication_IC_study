module line_rx_tb  ; 
 
  wire  [7:0]  o_data   ; 
  wire    o_rx_int   ; 
  wire    o_err   ; 
  
  reg    i_ce_n   ; 
  reg  [1:0]  i_verify_mode   ; 
  reg    i_clear_int_n   ; 
  reg    i_rst_n   ; 
  reg    i_clk   ; 
  reg    i_rx_data   ; 
  reg    i_clk_rx   ; 
  line_rx  
   DUT  ( 
       .o_data (o_data ) ,
      .i_ce_n (i_ce_n ) ,
      .i_verify_mode (i_verify_mode ) ,
      .o_rx_int (o_rx_int ) ,
      .i_clear_int_n (i_clear_int_n ) ,
      .i_rst_n (i_rst_n ) ,
      .i_clk (i_clk ) ,
      .o_err (o_err ) ,
      .i_rx_data (i_rx_data ) ,
      .i_clk_rx (i_clk_rx ) ); 

	  
	initial begin
		i_ce_n = 1 ;
		i_clear_int_n = 1;
		i_clk = 0;
		i_clk_rx = 0;
		i_verify_mode = 0 ;
		i_rx_data = 0;
		i_rst_n = 0;
	#200
		i_rst_n = 1;
	#50 
		i_verify_mode = 2;
	#50
		i_ce_n = 0 ;

	end
	  
	reg [3:0] cnt;
	initial cnt = 0;
	reg r_tmp;
	always @ (negedge i_clk_rx) begin
		if(cnt == 0 && !o_err) i_rx_data = 0 ;	//发送起始位
		else if(cnt>0 && cnt < 9) i_rx_data = ({$random} % 2 )^ r_tmp; //发送随机数据
		else if(cnt == 9 || cnt == 10 ) i_rx_data = 1 ;		//发送停止位
		else i_rx_data = 1 ;//发送空闲位
		r_tmp = i_rx_data;
		if(cnt <= 20 && !o_err) cnt <= cnt + 1;
		else cnt <= 0;
		
	end
	
	//清中断标志位
	always @(posedge o_rx_int) begin
		#200
			i_clear_int_n = 0;
		#100
			i_clear_int_n = 1;
	end
	
	//清错误标志位
	always @(posedge o_err) begin
		#200
			i_rst_n = 0;
		#100
			i_rst_n = 1;
	end
	
	always #50 i_clk = ~ i_clk;
	always begin
		#400 i_clk_rx = 1;
		#100 i_clk_rx = 0;
	end

endmodule
