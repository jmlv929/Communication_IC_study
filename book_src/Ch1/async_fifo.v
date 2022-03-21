   module fifo_async_8X256 #(parameter  DATA_WIDTH  = 8, ADDR_WID = 8, FIFO_DEPTH=(1 << ADDR_WID) )(
      input WClk,
      input Clear_in,
      input ReadEn_in,
      input RClk,
      input WriteEn_in,
      input [DATA_WIDTH-1:0]Data_in,
      output[DATA_WIDTH-1:0]Data_out,
      output reg            Empty_out,
      output reg            Full_out
   );
   wire [ADDR_WID-1:0] pNextWordToWrite,pNextWordToRead;
   wire                EqualAddresses;
   wire                NextWriteAddressEn, NextReadAddressEn;
   wire                Set_Status, Rst_Status;
   reg                 Status;
   wire                PresetFull, PresetEmpty;
   
   wire CENA=1'b0;//!(ReadEn_in & !Empty_out);
   wire CENB=!(WriteEn_in & !Full_out);
   wire [ADDR_WID-1:0] AA=pNextWordToRead;
   wire [ADDR_WID-1:0] AB=pNextWordToWrite;
   
   reg  rd_fifo_flag;
   wire [DATA_WIDTH-1:0] Data_out_rd;
   reg  [DATA_WIDTH-1:0] Data_out_rd_d0;
   
   always @ (posedge RClk)
     rd_fifo_flag<=(ReadEn_in & !Empty_out);
   always  @ (posedge RClk)
     if (rd_fifo_flag ) Data_out_rd_d0 <= Data_out_rd;
   
   assign Data_out=rd_fifo_flag ?  Data_out_rd : Data_out_rd_d0;
   DPRF8X256 #(.Bits(DATA_WIDTH),.Word_Depth(FIFO_DEPTH),.Add_Width(ADDR_WID) ) u_DPRF8X256(
        .QA   (Data_out_rd),// 输出数据口                 
        .CLKA (RClk   ),    //FIFO 读时钟                 
        .CLKB (WClk   ),    //FIFO 写时钟                 
        .CENA (CENA   ),    //FIFO 读功能片选使能         
        .CENB (CENB   ),    //FIFO 写功能片选使能         
        .AA   (AA     ),    //FIFO RAM读地址              
        .AB   (AB     ),    //FIFO RAM写地址              
        .DB   (Data_in));   // FIFO RAM 写入时钟       
   
   assign NextWriteAddressEn = WriteEn_in & ~Full_out;
   assign NextReadAddressEn  = ReadEn_in  & ~Empty_out;
   
   //Addreses (Gray counters) logic:
   GrayCounter #(.COUNTER_WIDTH(ADDR_WID)) GrayCounter_pWr(
     .GrayCount_out(pNextWordToWrite),
     .Enable_in(NextWriteAddressEn),
     .Clear_in(Clear_in),
     .Clk(WClk) );
   GrayCounter #(.COUNTER_WIDTH(ADDR_WID)) GrayCounter_pRd(
     .GrayCount_out(pNextWordToRead),
     .Enable_in(NextReadAddressEn),
     .Clear_in(Clear_in),
     .Clk(RClk) );
   assign EqualAddresses = (pNextWordToWrite == pNextWordToRead);
   assign Set_Status =
   (pNextWordToWrite[ADDR_WID-2] ~^ pNextWordToRead[ADDR_WID-1]) &
   (pNextWordToWrite[ADDR_WID-1] ^  pNextWordToRead[ADDR_WID-2]);
   assign Rst_Status=
   (pNextWordToWrite[ADDR_WID-2] ^ pNextWordToRead[ADDR_WID-1]) &
   (pNextWordToWrite[ADDR_WID-1] ~^ pNextWordToRead[ADDR_WID-2]);
   
    always @ (Set_Status, Rst_Status, Clear_in)
      if (Rst_Status | Clear_in) Status = 0;  //Going 'Empty'.
      else if (Set_Status) Status = 1;  //Going 'Full'.
   
    assign PresetFull = Status & EqualAddresses;  //'Full' Fifo.
    always @ (posedge WClk, posedge PresetFull)
      if (PresetFull) Full_out <= 1;
      else Full_out <= 0;
   
    assign PresetEmpty = ~Status & EqualAddresses;  //'Empty' Fifo
   
    always @ (posedge RClk, posedge PresetEmpty)
      if (PresetEmpty) Empty_out <= 1;
      else Empty_out <= 0;
    endmodule