`define P_EVEN 2'b00 //
`define P_ODD  2'b01 //
`define P_NONE 2'b10 //
module uart_tx(
input i_clk,         // ϵͳʱ������
input i_rst_n,       // ��λ����
input i_clk_tx,      // ��λʱ�����룬�벨����һ��
input i_start_n,     // ����uart����
input [7:0] i_data,  // �������룬��i_start_n��Чʱ����
input [1:0] i_parity,// У��ģʽ(��У�顢żУ�顢��У��)
output o_tx_data,    // �����������
output o_tx_int);    // ��������ж�

reg [7:0] txdata;
reg [1:0] txparity;
reg [3:0] txnum;
reg txstart;
// д�ڲ��Ĵ�������
// Process generates start signal for transmission
always @(posedge i_clk) begin
  if(!i_rst_n) begin
    txdata <= 0;
    txstart<= 0;
    txparity <= 0;
  end else if(!i_start_n) begin
    txdata <= i_data;
    txparity <= i_parity;
    txstart <= 1;
  end else if(txnum == 11) begin
    txstart <= 0;
    txparity<= 'bx;
    txdata  <= 'bx;
  end
end

// �߼����ӣ���i_start_n ��Ч��ƽ��ʧ��ſ�ʼ����
wire tx_start = txstart &  i_start_n ;
reg txd;
always @(posedge i_clk)
  if(!i_rst_n) begin
    txd <= 1;
    txnum <= 0;
  end else if(i_clk_tx && tx_start) begin
    txnum <= txnum + 1;
    case (txnum)
      0 : txd <= 0;   // ������ʼλ0
      1 : txd <= txdata[0];
      2 : txd <= txdata[1];
      3 : txd <= txdata[2];
      4 : txd <= txdata[3];
      5 : txd <= txdata[4];
      6 : txd <= txdata[5];
      7 : txd <= txdata[6];
      8 : txd <= txdata[7];
      9 : case(txparity)
          `P_EVEN : txd <= ~^ txdata ;// żУ�� txdata��λͬ�����
          `P_ODD  : txd <=  ^ txdata ;// ��У�� txdata��λ������
          `P_NONE : txd <= 1;         // ��У�� ��ǰ����ֹͣλ
          default : txd <= 1 ;
        endcase
      10: txd <= 1 ; // ����ֹͣλ1
      default : txd <= 1;
    endcase
  end else if(txnum == 11)
    txnum <= 0;

assign o_tx_data = txd ;

// �����жϲ�������
// Process generates interrupt signal for output
reg tx_int;
always @(posedge i_clk)
  if(!i_rst_n || (tx_start && txnum != 11))
    tx_int <= 0;
  else if( tx_start && txnum == 11)
    tx_int <= 1;

assign o_tx_int = tx_int ;

endmodule
