/******************************************************************************************
* Test Bench for SPI Master
* January 2007
*******************************************************************************************/

`timescale 10ns/1ns

module SPI_master_test;
    
wire [7:0] data_bus;     // Bidirectional
wire mosi;               // Output from main module
wire sclk;               // Output from main module
wire [7:0] ss;           // Output from main module

/* Inputs to main module */
reg miso;               
reg CS;
reg [1:0] addr;
reg pro_clk;
reg WR,RD;

SPI_Master tb ( miso, mosi, sclk, ss, data_bus, CS, addr, pro_clk, WR, RD);

/* Internal registers defined for TB */
reg [7:0] data_send;
reg [7:0] transmit_store;
reg [7:0] data_receive;
reg [7:0] miso_data;
reg [7:0] mosi_data;

assign data_bus = data_send;

initial                         // Generates serial clock of time period 10
  begin
    pro_clk = 0;
    forever #5 pro_clk = !pro_clk;
  end
  
initial 
  begin
    CS = 0;
    RD = 0;
    WR = 0;
    data_send = 0;
    addr = 0;
    miso = 0;
    
    #20
    /* Updating Control register */
    @ (negedge pro_clk)
    CS = 1;
    WR = 1;
    data_send = 0;            
    addr = 0;
    /* Updating Transmit buffer */
    @ (negedge pro_clk)
    CS = 1;
    WR = 1;
    data_send = $random; 
    addr = 2'b10;
    #1 transmit_store = data_send;
    @ (negedge pro_clk)
    $display ("Transmit Buffer loaded");
    $display ("SS[0] = 0, CPHA = 0, CPOL = 0 at time:",$time);
    $display ("Observe Waveform for spi clock frequency, spi data changing at falling egde, valid at rising edge");
    CS = 0;
    WR = 0;
    data_send = 8'bz;
    
    @ (posedge ss[0])
    #20
    
    /* Checking Status */
    @ (negedge pro_clk)
    CS = 1;
    RD = 1;
    addr = 2'b01;
    @ (negedge pro_clk)
    data_receive = data_bus;
    @ (negedge pro_clk)
    if (data_receive[0]) begin
        $display("Interrupt detected at time:", $time);
        addr = 2'b11;
    end else begin
        $display("Interrupt detect failed at time:", $time);
    end
    @ (negedge pro_clk)
    data_receive = data_bus;
    if (data_bus == miso_data) begin
        $display("Data received from spi slave verified", $time);
    end else begin
        $display("Data receive failed",$time);
    end
    /* Writing new control word */
    @ (negedge pro_clk)
    CS = 1;
    WR = 1;
    RD = 0;
    data_send = 8'b10001001;            
    addr = 0;
    @ (negedge pro_clk)
    CS = 1;
    WR = 1;
    data_send = $random; 
    addr = 2'b10;
    #1 transmit_store = data_send;
    @ (negedge pro_clk)
    $display ("\n Transmit Buffer reloaded");
    $display ("Observe Waveform for spi clock frequency, spi data changing at rising edge and valid at falling edge");
    $display ("SS[4] = 0, CPHA = 0, CPOL = 1 at time:",$time);
    CS = 0;
    RD = 0;
    WR = 0;
    data_send = 8'bz;
    
    @ (posedge ss[4])
    #20
    
    /* Checking Status */
    @ (negedge pro_clk)
    CS = 1;
    RD = 1;
    addr = 2'b01;
    @ (negedge pro_clk)
    data_receive = data_bus;
    @ (negedge pro_clk)
    if (data_receive[0]) begin
        $display("Interrupt detected at time:", $time);
        addr = 2'b11;
    end else begin
        $display("Interrupt detect failed at time:", $time);
    end
    @ (negedge pro_clk)
    data_receive = data_bus;
    if (data_bus == miso_data) begin
        $display("Data received from spi slave verified", $time);
    end else begin
        $display("Data receive failed",$time);
    end
    /* Writing new control word */
    @ (negedge pro_clk)
    CS = 1;
    WR = 1;
    RD = 0;
    data_send = 8'b11110010;            
    addr = 0;
    @ (negedge pro_clk)
    CS = 1;
    WR = 1;
    data_send = $random; 
    addr = 2'b10;
    #1 transmit_store = data_send;
    @ (negedge pro_clk)
    $display ("\n Transmit Buffer reloaded");
    $display ("Observe Waveform for spi clock frequency, spi data changing at rising edge and valid at falling edge");
    $display ("SS[7] = 0, CPHA = 1, CPOL = 0 at time:",$time);
    CS = 0;
    RD = 0;
    WR = 0;
    data_send = 8'bz;
    
    @ (posedge ss[7])
    #20
    
    /* Checking Status */
    @ (negedge pro_clk)
    CS = 1;
    RD = 1;
    addr = 2'b01;
    @ (negedge pro_clk)
    data_receive = data_bus;
    @ (negedge pro_clk)
    if (data_receive[0]) begin
        $display("interrupt detected at time:", $time);
        addr = 2'b11;
    end else begin
        $display("interrupt detect failed at time:", $time);
    end
    @ (negedge pro_clk)
    data_receive = data_bus;
    if (data_bus == miso_data) begin
        $display("Data received from spi slave verified", $time);
    end else begin
        $display("Data receive failed",$time);
    end
    /* Writing new control word */
    @ (negedge pro_clk)
    CS = 1;
    WR = 1;
    RD = 0;
    data_send = 8'b01111100;            
    addr = 0;
    @ (negedge pro_clk)
    CS = 1;
    WR = 1;
    data_send = $random; 
    addr = 2'b10;
    #1 transmit_store = data_send;
    @ (negedge pro_clk)
    $display ("\n Transmit Buffer reloaded");
    $display ("Observe Waveform for spi clock frequency, spi data changing at falling edge and valid at rising edge");
    $display ("SS[3] = 0, CPHA = 1, CPOL = 1 at time:",$time);
    CS = 0;
    RD = 0;
    WR = 0;
    data_send = 8'bz;
    
    @ (posedge ss[3])
    #20
    
    /* Checking Status */
    @ (negedge pro_clk)
    CS = 1;
    RD = 1;
    addr = 2'b01;
    @ (negedge pro_clk)
    data_receive = data_bus;
    @ (negedge pro_clk)
    if (data_receive[0]) begin
        $display("Interrupt detected at time:", $time);
        addr = 2'b11;
    end else begin
        $display("Interrupt detect failed at time:", $time);
    end
    @ (negedge pro_clk)
    data_receive = data_bus;
    if (data_bus == miso_data) begin
        $display("Data received from spi slave verified", $time);
    end else begin
        $display("Data receive failed",$time);
    end
    @ (negedge pro_clk)
    $display ("\n PASS: hit break to stop simulation");
      
end

initial 
begin
    /* Writing MISO / Reading MOSI for random values */
    #20
    miso_data = $random;
    @ (negedge ss[0])
    miso = miso_data[7];
    @ (posedge sclk)
    mosi_data[7] = mosi; 
    @ (negedge sclk)
    miso = miso_data[6];
    @ (posedge sclk)
    mosi_data[6] = mosi;
    @ (negedge sclk)
    miso = miso_data[5];
    @ (posedge sclk)
    mosi_data[5] = mosi;
    @ (negedge sclk)
    miso = miso_data[4];
    @ (posedge sclk)
    mosi_data[4] = mosi;
    @ (negedge sclk)
    miso = miso_data[3];
    @ (posedge sclk)
    mosi_data[3] = mosi;
    @ (negedge sclk)
    miso = miso_data[2];
    @ (posedge sclk)
    mosi_data[2] = mosi;
    @ (negedge sclk)
    miso = miso_data[1];
    @ (posedge sclk)
    mosi_data[1] = mosi;
    @ (negedge sclk)
    miso = miso_data[0];
    @ (posedge sclk)
    mosi_data[0] = mosi;
    #5 
    if(mosi_data == transmit_store) begin
        $display("Data transmitted to spi slave verified", $time );
    end else begin
        $display("Data Transmit to spi slave failed !", $time );
    end
    
    /* Next set : CPOL = 1, CPHA = 0 */        
    @ (negedge ss[4])
    miso_data = $random;
    miso = miso_data[7];
    @ (negedge sclk)
    mosi_data[7] = mosi; 
    @ (posedge sclk)
    miso = miso_data[6];
    @ (negedge sclk)
    mosi_data[6] = mosi;
    @ (posedge sclk)
    miso = miso_data[5];
    @ (negedge sclk)
    mosi_data[5] = mosi;
    @ (posedge sclk)
    miso = miso_data[4];
    @ (negedge sclk)
    mosi_data[4] = mosi;
    @ (posedge sclk)
    miso = miso_data[3];
    @ (negedge sclk)
    mosi_data[3] = mosi;
    @ (posedge sclk)
    miso = miso_data[2];
    @ (negedge sclk)
    mosi_data[2] = mosi;
    @ (posedge sclk)
    miso = miso_data[1];
    @ (negedge sclk)
    mosi_data[1] = mosi;
    @ (posedge sclk)
    miso = miso_data[0];
    @ (negedge sclk)
    mosi_data[0] = mosi;
    #5 
    if(mosi_data == transmit_store) begin
        $display("Data transmitted to spi slave verified", $time );
    end else begin
        $display("Data Transmit to spi slave failed !", $time );
    end
    
    /* Next set : CPOL = 0, CPHA = 1 */        
    @ (negedge ss[7])
    miso_data = $random;
    @ (posedge sclk)
    miso = miso_data[7];
    @ (negedge sclk)
    mosi_data[7] = mosi; 
    @ (posedge sclk)
    miso = miso_data[6];
    @ (negedge sclk)
    mosi_data[6] = mosi;
    @ (posedge sclk)
    miso = miso_data[5];
    @ (negedge sclk)
    mosi_data[5] = mosi;
    @ (posedge sclk)
    miso = miso_data[4];
    @ (negedge sclk)
    mosi_data[4] = mosi;
    @ (posedge sclk)
    miso = miso_data[3];
    @ (negedge sclk)
    mosi_data[3] = mosi;
    @ (posedge sclk)
    miso = miso_data[2];
    @ (negedge sclk)
    mosi_data[2] = mosi;
    @ (posedge sclk)
    miso = miso_data[1];
    @ (negedge sclk)
    mosi_data[1] = mosi;
    @ (posedge sclk)
    miso = miso_data[0];
    @ (negedge sclk)
    mosi_data[0] = mosi;
    #5 
    if(mosi_data == transmit_store) begin
        $display("Data transmitted to spi slave verified", $time );
    end else begin
        $display("Data Transmit to spi slave failed !", $time );
    end
    
    /* Next set : CPOL = 1, CPHA = 1 */        
    @ (negedge ss[3])
    miso_data = $random;
    @ (negedge sclk)
    miso = miso_data[7];
    @ (posedge sclk)
    mosi_data[7] = mosi; 
    @ (negedge sclk)
    miso = miso_data[6];
    @ (posedge sclk)
    mosi_data[6] = mosi;
    @ (negedge sclk)
    miso = miso_data[5];
    @ (posedge sclk)
    mosi_data[5] = mosi;
    @ (negedge sclk)
    miso = miso_data[4];
    @ (posedge sclk)
    mosi_data[4] = mosi;
    @ (negedge sclk)
    miso = miso_data[3];
    @ (posedge sclk)
    mosi_data[3] = mosi;
    @ (negedge sclk)
    miso = miso_data[2];
    @ (posedge sclk)
    mosi_data[2] = mosi;
    @ (negedge sclk)
    miso = miso_data[1];
    @ (posedge sclk)
    mosi_data[1] = mosi;
    @ (negedge sclk)
    miso = miso_data[0];
    @ (posedge sclk)
    mosi_data[0] = mosi;
    #5 
    if(mosi_data == transmit_store) begin
        $display("Data transmitted to spi slave verified", $time );
    end else begin
        $display("Data Transmit to spi slave failed !", $time );
    end
    
end

endmodule

/*************************************** END OF TB ***********************************************************************/