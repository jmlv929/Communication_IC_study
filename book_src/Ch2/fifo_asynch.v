//==========================================
// Function : Asynchronous FIFO (w/ 2 asynchronous clocks).
// Coder  : liqinghua.
// Date   : 15/May/2005.
// Notes  : This implementation is based on the article 
//      'Asynchronous FIFO in Virtex-II FPGAs'
//      writen by Peter Alfke. This TechXclusive 
//      article can be downloaded from the
//      Xilinx website. It has some minor modifications.
//=========================================

//fifo_async_8X256 #(
//   .DATA_WIDTH  (DATA_WIDTH   )
//  ,.ADDRESS_WIDTH (ADDRESS_WIDTH)
//  ,.FIFO_DEPTH  (FIFO_DEPTH   )
//) U_fifo_async_8X256 (  
//   .Data_out   (Data_out   ) 
//  ,.Empty_out  (Empty_out  ) 
//  ,.ReadEn_in  (ReadEn_in  ) 
//  ,.RClk     (RClk     )   
//         
//  ,.Data_in  (Data_in  ) 
//  ,.Full_out   (Full_out   ) 
//  ,.WriteEn_in (WriteEn_in ) 
//  ,.WClk     (WClk     ) 
//         
//  ,.Clear_in   (Clear_in   ) 
//);

module fifo_async_8X256
  #(parameter  DATA_WIDTH  = 8,
         ADDRESS_WIDTH = 8,
         FIFO_DEPTH  = (1 << ADDRESS_WIDTH))
   //Reading port
  (output    [DATA_WIDTH-1:0]    Data_out, 
   output reg              Empty_out,
   input wire              ReadEn_in,
   input wire              RClk,    
   //Writing port.	 
   input wire  [DATA_WIDTH-1:0]    Data_in,  
   output reg              Full_out,
   input wire              WriteEn_in,
   input wire              WClk,
	 
   input wire              Clear_in);

  /////Internal connections & variables//////
//  reg   [DATA_WIDTH-1:0]        Mem [FIFO_DEPTH-1:0];
  wire  [ADDRESS_WIDTH-1:0]       pNextWordToWrite, pNextWordToRead;
  wire                EqualAddresses;
  wire                NextWriteAddressEn, NextReadAddressEn;
  wire                Set_Status, Rst_Status;
  reg                 Status;
  wire                PresetFull, PresetEmpty;
  
  //////////////Code///////////////
  //Data ports logic:
  //(Uses a dual-port RAM).

//  //'Data_out' logic:
//  always @ (posedge RClk)
//    if (ReadEn_in & !Empty_out)
//      Data_out <= Mem[pNextWordToRead];
//      
//  //'Data_in' logic:
//  always @ (posedge WClk)
//    if (WriteEn_in & !Full_out)
//      Mem[pNextWordToWrite] <= Data_in;


wire CENA=1'b0;//!(ReadEn_in & !Empty_out);
wire CENB=!(WriteEn_in & !Full_out);
wire [ADDRESS_WIDTH-1:0] AA=pNextWordToRead;
wire [ADDRESS_WIDTH-1:0] AB=pNextWordToWrite;

reg  rd_fifo_flag;
wire [DATA_WIDTH-1:0] Data_out_rd;
reg  [DATA_WIDTH-1:0] Data_out_rd_d0;

always @ (posedge RClk)
  rd_fifo_flag<=(ReadEn_in & !Empty_out);

always  @ (posedge RClk)
	if (rd_fifo_flag )
  Data_out_rd_d0 <= Data_out_rd;

assign Data_out=rd_fifo_flag ? 	Data_out_rd : Data_out_rd_d0; 
DPRF8X256 #(
 .Bits      (DATA_WIDTH   )
,.Word_Depth(FIFO_DEPTH   )
,.Add_Width (ADDRESS_WIDTH)
)
u_DPRF8X256(
     .QA   (Data_out_rd)   
			  ,.CLKA (RClk   )  
			  ,.CLKB (WClk   )  
			  ,.CENA (CENA   )  
			  ,.CENB (CENB   )  
			  ,.AA   (AA     )  
			  ,.AB   (AB     )  
			  ,.DB   (Data_in)  
			  );
  //Fifo addresses support logic: 
  //'Next Addresses' enable logic:
  assign NextWriteAddressEn = WriteEn_in & ~Full_out;
  assign NextReadAddressEn  = ReadEn_in  & ~Empty_out;
       
  //Addreses (Gray counters) logic:
  GrayCounter #(.COUNTER_WIDTH(ADDRESS_WIDTH)) GrayCounter_pWr
     (.GrayCount_out(pNextWordToWrite),
     
    .Enable_in(NextWriteAddressEn),
    .Clear_in(Clear_in),
    
    .Clk(WClk)
     );
     
  GrayCounter #(.COUNTER_WIDTH(ADDRESS_WIDTH)) GrayCounter_pRd
     (.GrayCount_out(pNextWordToRead),
    .Enable_in(NextReadAddressEn),
    .Clear_in(Clear_in),
    .Clk(RClk)
     );
   

  //'EqualAddresses' logic:
  assign EqualAddresses = (pNextWordToWrite == pNextWordToRead);

//'Quadrant selectors' logic:
assign Set_Status = 
(pNextWordToWrite[ADDRESS_WIDTH-2] ~^ pNextWordToRead[ADDRESS_WIDTH-1]) &
(pNextWordToWrite[ADDRESS_WIDTH-1] ^  pNextWordToRead[ADDRESS_WIDTH-2]);
            
assign Rst_Status = 
(pNextWordToWrite[ADDRESS_WIDTH-2] ^  pNextWordToRead[ADDRESS_WIDTH-1]) &
(pNextWordToWrite[ADDRESS_WIDTH-1] ~^ pNextWordToRead[ADDRESS_WIDTH-2]);
           
//'Status' latch logic:
always @ (Set_Status, Rst_Status, Clear_in) //D Latch w/ Asynchronous Clear & Preset.
  if (Rst_Status | Clear_in)
    Status = 0;  //Going 'Empty'.
  else if (Set_Status)
    Status = 1;  //Going 'Full'.
    
//'Full_out' logic for the writing port:
assign PresetFull = Status & EqualAddresses;  //'Full' Fifo.

always @ (posedge WClk, posedge PresetFull) //D Flip-Flop w/ Asynchronous Preset.
  if (PresetFull)
    Full_out <= 1;
  else
    Full_out <= 0;
    
//'Empty_out' logic for the reading port:
assign PresetEmpty = ~Status & EqualAddresses;  //'Empty' Fifo.

always @ (posedge RClk, posedge PresetEmpty)  //D Flip-Flop w/ Asynchronous Preset.
  if (PresetEmpty)
    Empty_out <= 1;
  else
    Empty_out <= 0;
    
endmodule
