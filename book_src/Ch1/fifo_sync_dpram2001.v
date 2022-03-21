   module fifo_sync_dpram2001 #(
   parameter DATA_WIDTH = 8,
   parameter ADDR_WIDTH = 8) (
     input clk                       , // Clock input
     input rst                       , // Active high reset
     input wr_cs                     , // Write chip select
     input rd_cs                     , // Read chipe select
     input rd_en                     , // Read enable  
     input wr_en                     , // Write Enable 
     input [DATA_WIDTH-1:0] data_in  , // Data input  
     output full                     , // FIFO empty
     output empty                    , // FIFO full 
     output [DATA_WIDTH-1:0] data_out  // Data Output
   );    
   parameter RAM_DEPTH = (1 << ADDR_WIDTH);
   reg [ADDR_WIDTH-1:0] wr_pointer;
   reg [ADDR_WIDTH-1:0] rd_pointer;
   reg [ADDR_WIDTH :0] status_cnt;
   wire [DATA_WIDTH-1:0] data_ram ;
   //-----------Variable assignments---------------
   assign full = (status_cnt == (RAM_DEPTH-1));
   assign empty = (status_cnt == 0);
   //-----------Code Start---------------------------
   always @ (posedge clk or posedge rst) //WRITE_POINTER
     if (rst) begin
       wr_pointer <= 0;
     end else if (wr_cs && wr_en && ~full) begin
       wr_pointer <= wr_pointer + 1;
     end
   
   always @ (posedge clk or posedge rst) //READ_POINTER
     if (rst) begin
       rd_pointer <= 0;
     end else if (rd_cs && rd_en && !empty) begin
       rd_pointer <= rd_pointer + 1;
     end
   
   always @ (posedge clk or posedge rst) //STATUS_COUNTER
     if (rst) begin
       status_cnt <= 0;
     // Read but no write.
     end else if ((rd_cs && rd_en) && !(wr_cs && wr_en)
                   && (status_cnt != 0)) begin
       status_cnt <= status_cnt - 1;
     // Write but no read.
     end else if ((wr_cs && wr_en) && !(rd_cs && rd_en)
                  && (status_cnt != RAM_DEPTH)) begin
       status_cnt <= status_cnt + 1;
     end
   
   wire [DATA_WIDTH-1:0] data_out_rd;
   reg  [DATA_WIDTH-1:0] data_out_rd_d0;
   wire CENA=1'b0;
   wire CENB=1'b0;
   wire WENA=1'b1;
   wire WENB=!(wr_cs && wr_en);
   
   DPRAM_ASIC #(.Bits(DATA_WIDTH),.Word_Depth(RAM_DEPTH),.Add_Width(ADDR_WIDTH))
   U_DPRAM_ASIC(
     .QA   (data_out_rd),
     .QB   (           ),
     .CLKA (clk        ),
     .CLKB (clk        ),
     .CENA (CENA       ),
     .CENB (CENB       ),
     .WENA (WENA       ),
     .WENB (WENB       ),
     .AA   (rd_pointer ),
     .AB   (wr_pointer ),
     .DA   ('h0        ),
     .DB   (data_in    )
   );
   reg rd_fifo_flag;
   always  @ (posedge clk)
       rd_fifo_flag<=(rd_cs && rd_en && !empty);
   always  @ (posedge clk)
     if(rd_fifo_flag)
       data_out_rd_d0 <= data_out_rd;
   assign data_out=rd_fifo_flag ?  data_out_rd : data_out_rd_d0;
   // 由于双端口RAM互相影响，所以将RAM结果缓存到寄存器保证输出稳定性
   endmodule
   
   