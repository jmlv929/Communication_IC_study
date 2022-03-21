module mini_SPI_Slave(
  input clk,
  input SCK, SSEL, MOSI,
  output MISO,
  // SPI 数据接口
  input [7:0] tx_data,
  output reg[7:0] rx_data
);
// 对 SCK 进行3拍采样，消除不定态干扰
reg [2:0] SCK_d;
always @(posedge clk) SCK_d <= {SCK_d[1:0], SCK};
wire SCK_risingedge  = (SCK_d[2:1]==2'b01);  // now we can detect SCK rising edges
wire SCK_fallingedge = (SCK_d[2:1]==2'b10);  // and falling edges
// 对 SSEL_d 进行3拍采样，消除不定态干扰
reg [2:0] SSEL_d;
always @(posedge clk) SSEL_d <= {SSEL_d[1:0], SSEL};
wire SSEL_active = ~SSEL_d[1];  // SSEL is active low
wire SSEL_startmessage = (SSEL_d[2:1]==2'b10);  // message starts at falling edge
wire SSEL_endmessage = (SSEL_d[2:1]==2'b01);  // message stops at rising edge
// 对 MOSI 进行3拍采样，消除不定态干扰
reg [1:0] MOSI_d;
always @(posedge clk) MOSI_d <= {MOSI_d[0], MOSI};
wire MOSI_data = MOSI_d[1];
// SPI 中间变量，用于数据存储和计数
reg [2:0] bitcnt;  
reg byte_received;  // high when a byte has been received
reg [7:0] byte_data_received;
reg [7:0] byte_data_tx;
always @(posedge clk)
begin
  if( SSEL_active) begin
    if(SSEL_startmessage) byte_data_tx <= tx_data;
  end
  if(~SSEL_active) begin
    bitcnt <= 3'b000;
    byte_data_tx <= 8'h00;
  end
  else if(SCK_risingedge)begin
    bitcnt <= bitcnt + 3'b001;
    byte_data_received <= {byte_data_received[6:0], MOSI_data};
    byte_data_tx <= {byte_data_tx[6:0], 1'b0};
  end
end

always @(posedge clk) byte_received <= SSEL_active && SCK_risingedge && (bitcnt==3'b111);

always @(posedge clk) if(byte_received) rx_data <= byte_data_received;

assign MISO = byte_data_tx[7];  // send MSB first

endmodule
