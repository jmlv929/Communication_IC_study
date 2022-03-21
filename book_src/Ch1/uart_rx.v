`define P_EVEN 2'b00 //
`define P_ODD  2'b01 //
`define P_NONE 2'b10 //

module uart_rx(
  input i_clk,         //系统时钟输入
  input i_rst_n,       //复位输入
  input i_enable_n,    //允许传输输入
  input i_int_clrxn,   //清除中断输入
  input i_clk_rx,      //移位时钟输入，与波特率一致
  input i_rx_data,     //串行数据输入
  input [1:0] i_parity,//校验模式(奇校验、偶校验、无校验)
  output o_rx_int,     //接收中断输出
  output [7:0] o_data, //数据输出
  output o_err         //传输出错标志位
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
  if(!i_rst_n | rxerr) begin  //复位或传输发生错误则终止传输
    rxparity <= `P_NONE;
    rxstart <= 0;
  end else if(i_clk_rx && !i_rx_data && rxnum == 0) begin //收到起始位
    rxparity <= i_parity ;//每次开始传输的时候确认校验方式
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
      8 : case(rxparity)//核对校验位、若无校验则直接核对停止位
          `P_EVEN : rxerr <=  ^rxdata ^ i_rx_data ;
          `P_ODD  : rxerr <=  ^rxdata ^ i_rx_data ;
          `P_NONE : rxerr <= ~ i_rx_data ;
          default : rxerr <= ~ i_rx_data ;
        endcase
      9 : rxerr <= ~ i_rx_data | rxerr ;//检测停止位
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
  end else if(!i_int_clrxn) begin //手动清除中断标志
    rx_int <= 0;
    data <= 'bz;
  end

assign o_rx_int = rx_int ;
assign o_data = data ;

endmodule
