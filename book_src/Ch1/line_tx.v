`define P_EVEN 2'b00 //
`define P_ODD  2'b01 //
`define P_NONE 2'b10 //
module line_tx(
	input i_clk,         //ϵͳʱ������
	input i_rst_n,       //��λ����
	input i_clk_tx,      //��λʱ�����룬�벨����һ��
	input i_start_n,     //����uart����
	input [7:0] i_data,  //�������룬��i_start_n��Чʱ����
	input [1:0] i_parity,//У��ģʽ(��У�顢żУ�顢��У��)
	output o_tx_data,    //�����������
	output o_tx_int);    //��������ж�

	reg [7:0] txdata;
	reg [1:0] t_parity;
	reg [3:0] txnum;
	reg txstart;
	//д�ڲ��Ĵ�������
	//Process generates start signal for transmission
	always @(posedge i_clk) begin
		if(!i_rst_n) begin
			txdata <= 0;
			txstart<= 0;
			t_parity <= 0;
		end	else if(!i_start_n) begin
			txdata <= i_data;
			t_parity <= i_parity;
			txstart <= 1;
		end	else if(txnum == 11) begin
			txstart <= 0;
			t_parity<= 'bx;
			txdata  <= 'bx;
		end
	end
	
	//�߼����ӣ���i_start_n ��Ч��ƽ��ʧ��Ų�����Ч��ʼ�ź�(��ʼ����)
	wire tx_start = txstart &  i_start_n ;
	reg r_o_tx_data;
	always @(posedge i_clk) begin
		if(!i_rst_n) begin
			r_o_tx_data <= 1;
			txnum <= 0;
		end	else if(i_clk_tx && tx_start) begin
			txnum <= txnum + 1;
			case (txnum) 
				0 : r_o_tx_data <= 0;		//Start bit '0'//������ʼλ0
				1 : r_o_tx_data <= txdata[0];
				2 : r_o_tx_data <= txdata[1];
				3 : r_o_tx_data <= txdata[2];
				4 : r_o_tx_data <= txdata[3];
				5 : r_o_tx_data <= txdata[4];
				6 : r_o_tx_data <= txdata[5];
				7 : r_o_tx_data <= txdata[6];
				8 : r_o_tx_data <= txdata[7];
				9 :	case(t_parity)
						`P_EVEN	: r_o_tx_data <= ~^ txdata ;	//żУ�� txdata��λͬ�����
						`P_ODD	: r_o_tx_data <=  ^ txdata ;	//��У�� txdata��λ������
						`P_NONE	: r_o_tx_data <= 1;				//��У�� ��ǰ����ֹͣλ(���൱�ڶ�����1����λʱ������)
						default	: r_o_tx_data <= 1 ;
					endcase
				10: r_o_tx_data <= 1 ;		//End bit '1' //����ֹͣλ1
				default : r_o_tx_data <= 1;
			endcase
		
		end else if(txnum == 11) txnum <= 0;
	
	end
	assign o_tx_data = r_o_tx_data ;
	
	
	//�����жϲ�������
	//Process generates interrupt signal for output
	reg r_o_tx_int;
	always @(posedge i_clk)
		if(!i_rst_n || (tx_start && txnum != 11)) 
		  r_o_tx_int <= 0;
		else if( tx_start && txnum == 11)
		  r_o_tx_int <= 1;

	assign o_tx_int = r_o_tx_int ;

endmodule
