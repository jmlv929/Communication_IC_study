`define P_EVEN 2'b00 //
`define P_ODD  2'b01 //
`define P_NONE 2'b10 //

module uart_rx(
  input i_clk,         //ϵͳʱ������
  input i_rst_n,       //��λ����
  input i_enable_n,    //����������
  input i_int_clrxn,   //����ж�����
  input i_clk_rx,      //��λʱ�����룬�벨����һ��
  input i_rx_data,     //������������
  input [1:0] i_parity,//У��ģʽ(��У�顢żУ�顢��У��)
  output o_rx_int,     //�����ж����
  output [7:0] o_data, //�������
  output o_err         //��������־λ
);

reg [7:0] rxdata;
reg [3:0] rxnum;

reg [1:0] rxparity;
reg rxerr;
reg rxstart;
wire rx_start = rxstart & ~i_enable_n ;
wire none_parity_finish=(rxnum==9&&rxparity == `P_NONE);
wire parity_finish=(rxnum==10&&(rxparity==`P_EVEN||rxparity==`P_ODD));

always @(posedge i_clk)
  if(!i_rst_n | rxerr) begin  //��λ���䷢����������ֹ����
    rxparity <= `P_NONE;
    rxstart <= 0;
  end else if(i_clk_rx && !i_rx_data && rxnum == 0) begin //�յ���ʼλ
    rxparity <= i_parity ;//ÿ�ο�ʼ�����ʱ��ȷ��У�鷽ʽ
    rxstart<= 1;
  end else if(i_rx_data&&(none_parity_finish|parity_finish))begin
    rxparity <= `P_NONE;
    rxstart <= 0;
  end


always @ (posedge i_clk)
  if(!i_rst_n) begin
    rxnum <= 0;
    rxdata <= 0;
    rxerr <= 0;
  end else if(rx_start && i_clk_rx) begin
    rxnum <= rxnum + 1;
    case (rxnum)
      0 : begin  rxdata[0] <= i_rx_data ; rxerr <= 0 ; end
      1 : rxdata[1] <= i_rx_data ;
      2 : rxdata[2] <= i_rx_data ;
      3 : rxdata[3] <= i_rx_data ;
      4 : rxdata[4] <= i_rx_data ;
      5 : rxdata[5] <= i_rx_data ;
      6 : rxdata[6] <= i_rx_data ;
      7 : rxdata[7] <= i_rx_data ;
      8 : case(rxparity)//�˶�У��λ������У����ֱ�Ӻ˶�ֹͣλ
          `P_EVEN : rxerr <=  ^rxdata ^ i_rx_data ;
          `P_ODD  : rxerr <=  ^rxdata ^ i_rx_data ;
          `P_NONE : rxerr <= ~ i_rx_data ;
          default : rxerr <= ~ i_rx_data ;
        endcase
      9 : rxerr <= ~ i_rx_data | rxerr ;//���ֹͣλ
    endcase
  end else if(none_parity_finish|parity_finish) begin
    rxnum <= 0;
  end

assign o_err = rxerr ;

reg [7:0] data;
reg rx_int;
always @ (posedge i_clk)
  if(!i_rst_n) begin
    data <= 0;
    rx_int <= 0;
  end else if(none_parity_finish|parity_finish) begin
    if(!rxerr) begin
      data <= rxdata;
      rx_int <= 1;
    end else begin
      data <= 'bz;
      rx_int <= 0;
    end
  end else if(!i_int_clrxn) begin //�ֶ�����жϱ�־
    rx_int <= 0;
    data <= 'bz;
  end

assign o_rx_int = rx_int ;
assign o_data = data ;

endmodule
