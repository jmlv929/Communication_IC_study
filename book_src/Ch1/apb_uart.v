    //     Offset    Register Name       Read/Write         Width
    //     -------------------------------------------------------
    //      0x00     Transmit data       (Write only)       8 bits
    //      0x04     Receive data        (Read only)        8 bits
    //      0x08     Control Register 1  (R/W)              8 bits
    //      0x0C     Control Register 2  (R/W)              3 bits
    //      0x10     Status Register     (Read Only)        4 bits
    module CoreUARTapb (
        input           PCLK,       // APB system clock
        input           PRESETN,    // APB system reset
        input    [4:0]  PADDR,      // Address
        input           PSEL,       // Peripheral select signal
        input           PENABLE,    // Enable (data valid strobe)
        input           PWRITE,     // Write/nRead signal
        input    [7:0]  PWDATA,     // 8 bit write data
        output   [7:0]  PRDATA,     // 8 bit read data
        // transmit ready and receive full indicators
        output          TXRDY,
        output          RXRDY,
        input           RX,  // Serial receive and transmit data
        output          TX,
        output          PARITY_ERR,
        output          OVERFLOW 
    );
    parameter BAUD_VALUE = 0; // Baud value is set only when fixed buad rate is selected
    parameter FIXEDMODE = 0;  // fixed or programmable mode, 0: programmable; 1:fixed
    parameter PRG_BIT8 = 0;   // This bit value is selected only when FIXEDMODE is set to 1
    parameter PRG_PARITY = 0; // This bit value is selected only when FIXEDMODE is set to 1
    parameter RX_LEGACY_MODE = 0;  // legacy mode for RXRDY signal operation
    
    `define UARTTXDATAA     3'b000
    `define UARTRXDATAA     3'b001
    `define UARTCTRLREG1A   3'b010
    `define UARTCTRLREG2A   3'b011
    `define UARTSTATUSREGA  3'b100
    
    // Internal signals
    reg      [7:0]  controlReg1;                     
    reg      [7:0]  controlReg2;                     
    reg      [7:0]  NxtPrdata;                       
    reg      [7:0]  iPRDATA;                         
    wire            NxtPrdataEn;    //  valid read   
    wire     [7:0]  data_in;                         
    wire     [7:0]  data_out;                        
    wire     [12:0] baud_val;                        
    wire           bit8;           
    wire           parity_en;      
    wire           odd_n_even;     
    wire           WEn;            
    wire           OEn;            
    wire           csn;            
    //wire           OVERFLOW;       
    //wire           PARITY_ERR;     
    wire [1:0]     gen_parity_en;  
    wire           prg_parity_en;  
    wire           prg_odd_even;   
    wire           framing_err;    
    // Write enable, output enable and select signals for UART
    // WEn only asserted (low) when writing transmit data
    assign WEn = !(PENABLE &&  PWRITE && (PADDR[4:2] == `UARTTXDATAA));
    assign OEn = !(PENABLE && !PWRITE && (PADDR[4:2] == `UARTRXDATAA));
    assign csn = !PSEL;
    
    assign data_in = PWDATA; // data_in input to UART is used for transmit data
    // NxtPrdataEn is asserted during the first cycle of a valid read
    assign NxtPrdataEn = (PSEL & !PWRITE & !PENABLE);
    
    always @( * )
      if (NxtPrdataEn)
        case (PADDR[4:2])
          `UARTTXDATAA    : NxtPrdata = 8'b0;          // transmit data location reads as 0x00
          `UARTRXDATAA    : NxtPrdata = data_out;      // received data
          `UARTCTRLREG1A  : NxtPrdata = controlReg1;   // control reg 1 - baud value
          `UARTCTRLREG2A  : NxtPrdata = controlReg2;   // control reg 2 - bit8, parity_en, odd_n_even
          `UARTSTATUSREGA : NxtPrdata = {3'b0, framing_err, OVERFLOW, PARITY_ERR, RXRDY, TXRDY}; // status register
          default         : NxtPrdata = iPRDATA;
        endcase
      else
        NxtPrdata = iPRDATA;
    
    assign gen_parity_en = PRG_PARITY;
    assign prg_parity_en = (gen_parity_en == 2'd1 || gen_parity_en == 2'd2) ? 1'b1 : 1'b0;
    assign prg_odd_even =  (gen_parity_en == 2'd1) ? 1'b1 : 1'b0;
     // PRDATA output register
    always @ (posedge PCLK or negedge PRESETN)
     if (!PRESETN)
         iPRDATA <= 8'b0;
     else
         iPRDATA <= NxtPrdata;
    assign PRDATA = iPRDATA;
    always @(posedge PCLK or negedge PRESETN)
      if (!PRESETN)
          controlReg1 <= 8'b0;
      else if (PSEL && PENABLE && PWRITE && (PADDR[4:2] == `UARTCTRLREG1A))
              controlReg1 <= PWDATA;
      else
         controlReg1 <= controlReg1;
    
    assign baud_val = FIXEDMODE ? BAUD_VALUE:{controlReg2[7:3],controlReg1};
    
    always @(posedge PCLK or negedge PRESETN)
      if (!PRESETN)
        controlReg2 <= 8'b0;
      else if (PSEL && PENABLE && PWRITE && (PADDR[4:2] == `UARTCTRLREG2A))
        controlReg2 <= PWDATA[7:0];
      else
        controlReg2 <= controlReg2;
    
    assign bit8       = FIXEDMODE ? PRG_BIT8:controlReg2[0];
    assign parity_en  = FIXEDMODE ? prg_parity_en:controlReg2[1];
    assign odd_n_even = FIXEDMODE ? prg_odd_even:controlReg2[2];
    
        //----------------------------------------------------------------------
        // Instantiation of UART
        //----------------------------------------------------------------------
        COREUART#(
            .TX_FIFO      (TX_FIFO),
            .RX_FIFO      (RX_FIFO),
            .RX_LEGACY_MODE(RX_LEGACY_MODE)
         )
        uUART (
            .RESET_N        (PRESETN),
            .CLK            (PCLK),
            .WEN            (WEn),
            .OEN            (OEn),
            .CSN            (csn),
            .DATA_IN        (data_in),
            .RX             (RX),
            .BAUD_VAL       (baud_val),
            .BIT8           (bit8),
            .PARITY_EN      (parity_en),
            .ODD_N_EVEN     (odd_n_even),
            .FRAMING_ERR    (framing_err),
            .PARITY_ERR     (PARITY_ERR),
            .OVERFLOW       (OVERFLOW),
            .TXRDY          (TXRDY),
            .RXRDY          (RXRDY),
            .DATA_OUT       (data_out),
            .TX             (TX)
        );
    
    endmodule
    