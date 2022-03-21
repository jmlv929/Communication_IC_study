`define P_EVEN 2'b00 //
`define P_ODD  2'b01 //
`define P_NONE 2'b10 //
module uart_tx(
input i_clk,         // 系统时钟输入
input i_rst_n,       // 复位输入
input i_clk_tx,      // 移位时钟输入，与波特率一致
input i_start_n,     // 启动uart发送
input [7:0] i_data,  // 数据输入，在i_start_n有效时载入
input [1:0] i_parity,// 校验模式(奇校验、偶校验、无校验)
output o_tx_data,    // 串行数据输出
output o_tx_int);    // 发送完成中断

reg [7:0] txdata;
reg [1:0] txparity;
reg [3:0] txnum;
reg txstart;
// 写内部寄存器进程
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

// 逻辑连接，在i_start_n 有效电平消失后才开始传输
wire tx_start = txstart &  i_start_n ;
reg txd;
always @(posedge i_clk)
  if(!i_rst_n) begin
    txd <= 1;
    txnum <= 0;
  end else if(i_clk_tx && tx_start) begin
    txnum <= txnum + 1;
    case (txnum)
      0 : txd <= 0;   // 发送起始位0
      1 : txd <= txdata[0];
      2 : txd <= txdata[1];
      3 : txd <= txdata[2];
      4 : txd <= txdata[3];
      5 : txd <= txdata[4];
      6 : txd <= txdata[5];
      7 : txd <= txdata[6];
      8 : txd <= txdata[7];
      9 : case(txparity)
          `P_EVEN : txd <= ~^ txdata ;// 偶校验 txdata各位同或输出
          `P_ODD  : txd <=  ^ txdata ;// 奇校验 txdata各位异或输出
          `P_NONE : txd <= 1;         // 无校验 提前发送停止位
          default : txd <= 1 ;
        endcase
      10: txd <= 1 ; // 发送停止位1
      default : txd <= 1;
    endcase
  end else if(txnum == 11)
    txnum <= 0;

assign o_tx_data = txd ;

// 传输中断产生进程
// Process generates interrupt signal for output
reg tx_int;
always @(posedge i_clk)
  if(!i_rst_n || (tx_start && txnum != 11))
    tx_int <= 0;
  else if( tx_start && txnum == 11)
    tx_int <= 1;

assign o_tx_int = tx_int ;

endmodule
