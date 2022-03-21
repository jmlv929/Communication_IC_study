`define VERIFY_EVEN 2'b00
`define VERIFY_ODD	2'b01
`define VERIFY_NONE 2'b10

module line_rx(
	i_clk,		//系统时钟输入
	i_clk_rx,	//移位时钟输入
	i_rx_data,	//串行数据输入
	i_verify_mode,//校验模式(允许：奇校验、偶校验、无校验)输入
	i_rst_n,	//复位输入
	i_ce_n,		//允许传输输入
	i_clear_int_n,//清除中断输入
	o_rx_int,	//接收中断输出
	o_data	,	//数据输出，在中断有?时可被读取
	o_err		//传输出错标志位
);

	input i_clk;
	input i_clk_rx;
	input i_rx_data;
	input [1:0] i_verify_mode;
	input i_rst_n;
	input i_ce_n;
	input i_clear_int_n;
	output o_rx_int;
	output [7:0] o_data;
	output o_err;

	reg [7:0] r_data;
	reg [3:0] r_num;
	
	reg [1:0] r_verify_mode;
	reg r_err;	
	reg r_start;
	//写控制寄存器进程，确认何时开启传输
	always @(posedge i_clk) begin
		if(!i_rst_n | r_err) begin	//复位或传输发生错误则终止传输
			r_verify_mode <= `VERIFY_NONE;
			r_start <= 0;
		end else if(i_clk_rx && !i_rx_data && r_num == 0) begin	//收到起始位
			r_verify_mode <= i_verify_mode ;	//每次开始传输的时候确认校验方式
			r_start<= 1;
		end else if( i_rx_data && 					//已经收到停止位，停止传输
					((r_num == 9 && r_verify_mode == `VERIFY_NONE) ||
					(r_num ==  10 && (r_verify_mode == `VERIFY_EVEN || r_verify_mode == `VERIFY_ODD) ))
					) begin
			r_verify_mode <= `VERIFY_NONE;
			r_start <= 0;
		end
	end
	
	//逻辑连接 确定允许传输信号
	wire w_start ;
	assign w_start = r_start & ~i_ce_n ;
	
	always @ (posedge i_clk) begin
		if(!i_rst_n) begin
			r_num <= 0;
			r_data <= 0;
			r_err <= 0;
		end else if(w_start && i_clk_rx) begin
			r_num <= r_num + 1;
			case (r_num) 
				0 : begin  r_data[0] <= i_rx_data ; r_err <= 0 ; end
				1 : r_data[1] <= i_rx_data ;
				2 : r_data[2] <= i_rx_data ;
				3 : r_data[3] <= i_rx_data ;
				4 : r_data[4] <= i_rx_data ;
				5 : r_data[5] <= i_rx_data ;
				6 : r_data[6] <= i_rx_data ;
				7 : r_data[7] <= i_rx_data ;
				8 : casex(r_verify_mode) 		//核对校验位、若无校验则直接核对停止位
						`VERIFY_EVEN : r_err <=  ^r_data ^ i_rx_data ;
						`VERIFY_ODD  : r_err <=  ^r_data ^ i_rx_data ;
						`VERIFY_NONE : r_err <= ~ i_rx_data ;
						default 	 : r_err <= ~ i_rx_data ;
					endcase
				9 : r_err <= ~ i_rx_data | r_err ;//检测停止位
			endcase
		end else if((r_num == 9 && r_verify_mode == `VERIFY_NONE)  ||		//传输完毕
					(r_num == 10 && (r_verify_mode == `VERIFY_EVEN || r_verify_mode == `VERIFY_ODD) )) begin
			r_num <= 0;
		end
	end
	assign o_err = r_err ;
	
	reg [7:0] r_o_data;
	reg r_o_rx_int;
	always @ (posedge i_clk) begin
		if(!i_rst_n) begin
			r_o_data <= 0;
			r_o_rx_int <= 0;
		end else if((r_num == 9 && r_verify_mode == `VERIFY_NONE)  ||		//传输完毕
					(r_num == 10 && (r_verify_mode == `VERIFY_EVEN || r_verify_mode == `VERIFY_ODD) )) begin
			if(!r_err) begin
				r_o_data <= r_data;
				r_o_rx_int <= 1;
			end else begin
				r_o_data <= 'bz;
				r_o_rx_int <= 0;
			end
		end else if(!i_clear_int_n) begin	//手动清除中断标志
			r_o_rx_int <= 0;
			r_o_data <= 'bz;
		end 
	end
	assign o_rx_int = r_o_rx_int ;
	assign o_data = r_o_data ;
	
	
endmodule
