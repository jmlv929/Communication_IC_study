module spi(
input sck,  // spi clk
input cs,   // spi enable
input rw,   // slave read(0) & write(1)
input sdi,  // spi data input
input     [7:0] txdata,//spi output
output reg[7:0] rxdata,//spi output
output reg sdo // spi data output
);
reg[7:0] spi_out;
reg[7:0] spi_in;
reg msg_spiout_trg;
reg msg_spiout_fb;
 
always@(posedge sck)
  if(cs==0 & rw==0) begin//MOSI enable
    spi_in[0:0]=sdi;
    spi_in=spi_in<<1;
  end

always@(negedge sck)begin
  if(msg_spiout_trg)begin
    spi_out<=txdata;   //TXD assignment.U can put a variable instead of it.
    msg_spiout_fb<=1;
  end
  else 
    msg_spiout_fb<=0;

  if( cs==0 & rw==1)begin //MISO enable
    sdo=spi_out[7];
    spi_out=spi_out<<1;
  end
end

always@(posedge cs)   //cs=1 means Master write complete
  rxdata=~spi_in;  //use data received,for example...
 
always@(negedge rw or posedge msg_spiout_fb)begin 
  if(rw==0)
   msg_spiout_trg=1;
  
  if(msg_spiout_fb==1)
   msg_spiout_trg=0;
end
 
endmodule
