`define VERIFY_EVEN 2'b00
`define VERIFY_ODD	2'b01
`define VERIFY_NONE 2'b10

module line_rx(
	i_clk,		//ϵͳʱ������
	i_clk_rx,	//��λʱ������
	i_rx_data,	//������������
	i_verify_mode,//У��ģʽ(������У�顢żУ�顢��У��)����
	i_rst_n,	//��λ����
	i_ce_n,		//����������
	i_clear_int_n,//����ж�����
	o_rx_int,	//�����ж����
	o_data	,	//������������ж���?ʱ�ɱ���ȡ
	o_err		//��������־λ
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
	//д���ƼĴ������̣�ȷ�Ϻ�ʱ��������
	always @(posedge i_clk) begin
		if(!i_rst_n | r_err) begin	//��λ���䷢����������ֹ����
			r_verify_mode <= `VERIFY_NONE;
			r_start <= 0;
		end else if(i_clk_rx && !i_rx_data && r_num == 0) begin	//�յ���ʼλ
			r_verify_mode <= i_verify_mode ;	//ÿ�ο�ʼ�����ʱ��ȷ��У�鷽ʽ
			r_start<= 1;
		end else if( i_rx_data && 					//�Ѿ��յ�ֹͣλ��ֹͣ����
					((r_num == 9 && r_verify_mode == `VERIFY_NONE) ||
					(r_num ==  10 && (r_verify_mode == `VERIFY_EVEN || r_verify_mode == `VERIFY_ODD) ))
					) begin
			r_verify_mode <= `VERIFY_NONE;
			r_start <= 0;
		end
	end
	
	//�߼����� ȷ���������ź�
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
				8 : casex(r_verify_mode) 		//�˶�У��λ������У����ֱ�Ӻ˶�ֹͣλ
						`VERIFY_EVEN : r_err <=  ^r_data ^ i_rx_data ;
						`VERIFY_ODD  : r_err <=  ^r_data ^ i_rx_data ;
						`VERIFY_NONE : r_err <= ~ i_rx_data ;
						default 	 : r_err <= ~ i_rx_data ;
					endcase
				9 : r_err <= ~ i_rx_data | r_err ;//���ֹͣλ
			endcase
		end else if((r_num == 9 && r_verify_mode == `VERIFY_NONE)  ||		//�������
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
		end else if((r_num == 9 && r_verify_mode == `VERIFY_NONE)  ||		//�������
					(r_num == 10 && (r_verify_mode == `VERIFY_EVEN || r_verify_mode == `VERIFY_ODD) )) begin
			if(!r_err) begin
				r_o_data <= r_data;
				r_o_rx_int <= 1;
			end else begin
				r_o_data <= 'bz;
				r_o_rx_int <= 0;
			end
		end else if(!i_clear_int_n) begin	//�ֶ�����жϱ�־
			r_o_rx_int <= 0;
			r_o_data <= 'bz;
		end 
	end
	assign o_rx_int = r_o_rx_int ;
	assign o_data = r_o_data ;
	
	
endmodule
