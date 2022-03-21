/***********************************************************************************************
* SPI MASTER
* January 2007
************************************************************************************************/
`timescale 10ns/1ns
module SPI_Master ( miso, mosi, sclk, ss, data_bus, CS, addr, pro_clk, WR, RD);

inout [7:0] data_bus;           // 8 bit bidirectional data bus
input pro_clk;                  // Host Processor clock
input miso;                     // Master in slave out
input [1:0] addr;               // A1 and A0, lower bits of address bus
input CS;                       // Chip Select
input WR, RD;                   // Write and read enables

output mosi;                    // Master out slave in
output sclk;                    // SPI clock
output [7:0] ss;                // 8 slave select lines

reg [7:0] shift_register;        // Shift register
reg [7:0] txdata;                // Transmit buffer
reg [7:0] rxdata;                // Receive buffer
reg [7:0] data_out;              // Data output register
reg [7:0] data_out_en;           // Data output enable 
reg [7:0] control, status;       // Control Register COntrols things like ss, CPOL, CPHA, clock divider
                                 // Status Register is a dummy register never used.

reg [7:0] clk_divide;            // Clock divide counter
reg [3:0] count;                 // SPI word length counter
reg sclk;                        
reg slave_cs;                    // Slave cs flag
reg mosi;                  // Master out slave in
reg spi_word_send;               // Will send a new spi word.

wire [7:0] data_bus;
wire [7:0] data_in = data_bus;
wire spi_clk_gen;
wire [2:0] divide_factor = control[2:0];
wire CPOL = control[3];          
wire CPHA = control[4];
wire [7:0]ss; 


/* Slave Select lines */
assign ss[7] = ~( control[7] &  control[6] &  control[5] & (~slave_cs)); 
assign ss[6] = ~( control[7] &  control[6] & ~control[5] & (~slave_cs)); 
assign ss[5] = ~( control[7] & ~control[6] &  control[5] & (~slave_cs)); 
assign ss[4] = ~( control[7] & ~control[6] & ~control[5] & (~slave_cs)); 
assign ss[3] = ~(~control[7] &  control[6] &  control[5] & (~slave_cs)); 
assign ss[2] = ~(~control[7] &  control[6] & ~control[5] & (~slave_cs)); 
assign ss[1] = ~(~control[7] & ~control[6] &  control[5] & (~slave_cs)); 
assign ss[0] = ~(~control[7] & ~control[6] & ~control[5] & (~slave_cs)); 

/* clock divide */
assign spi_clk_gen = clk_divide[divide_factor];

/* Clock Divider */
always @ (negedge pro_clk) begin
    clk_divide = clk_divide + 1;     
end

/* Reading the miso line and shifting */
always @ (posedge (sclk ^ (CPHA ^ CPOL)) or posedge spi_word_send) begin
    if (spi_word_send) begin
        shift_register[7:0] = txdata;
    end else begin 
        shift_register = shift_register << 1;
        shift_register[0] <= miso;
    end
end

/* Writing the mosi */
always @ (negedge (sclk ^ (CPHA ^ CPOL)) or posedge spi_word_send) begin
    if (spi_word_send) begin
        mosi = txdata[7];
    end else begin 
        mosi = shift_register[7];
    end
end

/* Contolling the interrupt bit in the status bit */
always @ (posedge slave_cs or posedge spi_word_send) begin
    if (spi_word_send) begin
        status[0] = 0;
    end else begin
      status = 8'h01;
    rxdata = shift_register;         // updating read buffer
  end
end
   
/* New SPI wrod starts when the transmit buffer is updated */
always @ (posedge pro_clk) begin
    if (spi_word_send) begin
        slave_cs <= 0;
    end else if ((count == 8) & ~(sclk ^ CPOL)) begin
        slave_cs <= 1;
    end    
end

/* New Spi word is intiated when transmit buffer is updated */
always @ (posedge pro_clk) begin
    if (CS & WR & addr[1] & ~addr[0]) begin
        spi_word_send <=1;
    end else begin
        spi_word_send <=0;
    end
end

/* Generating the SPI clock */
always @ (posedge spi_clk_gen) begin
    if (~slave_cs) begin
        sclk = ~sclk;
    end else if (~CPOL) begin
        sclk = 0; 
    end else begin
        sclk = 1;
    end
end

/* Counting SPI word length */
always @ (posedge sclk or posedge slave_cs) begin
    if (slave_cs) begin
        count = 0;
    end else begin   
        count = count + 1;
    end
end

/* Reading, writing SPI registers */
always @ (posedge pro_clk) begin
    if (CS) begin
        case (addr) 
        2'b00 : if (WR) control <= data_in;
        2'b01 : if (RD) data_out <= status;   // Void 
      2'b10 : if (WR) txdata <= data_in;
      2'b11 : if (RD) data_out <= rxdata;
        endcase
    end
end

/* Controlling the data out enable */
always @ (RD or data_out) begin
    if (RD) 
    data_out_en = data_out;
    else
    data_out_en = 8'bz;
end

assign data_bus = data_out_en;

initial 
begin
    mosi = 0;
    //sclk = 0;
    control = 0;
    count = 0;
    slave_cs = 1;
    txdata = 0;
    rxdata = 0;
    clk_divide = 0;
    data_out = 0;
end

endmodule

/********************************************** END ******************************************************************/