 
 // data access sizes
 `define WORD    2'b10
 `define HWORD   2'b01
 `define BYTE    2'b00
 
 // AHB Definitions:
 
 `define AHB_TRANS_IDLE      2'b00
 `define AHB_TRANS_BUSY      2'b01
 `define AHB_TRANS_NONSEQ    2'b10
 `define AHB_TRANS_SEQ       2'b11
 
 `define AHB_RESP_OKAY       2'b00
 `define AHB_RESP_ERROR      2'b01
 `define AHB_RESP_RETRY      2'b10
 `define AHB_RESP_SPLIT      2'b11
 
 // AHB Bus Master Definitions:
 
 `define PROC_BUS_MASTER         0
 `define LCD_BUS_MASTER          1
 `define MSTR2_BUS_MASTER        2   // unused bus master
 
 `define N_BUS_MASTERS           3
 `define LOG_N_BUS_MASTERS       2
 
 
 
 module socAhbApbBridge (
   input  HCLK,
   input  HRESETn,             // active low reset
   input  [31:0] HADDR,        // AHB Address
   input  [31:0] HWDATA,       // write data from AHB Master
   input  HWRITE,              // 1 = write, 0= read
   input  HSEL,                // block select
   input  HREADY,              // ready input from other AHB slaves
   input  [1:0] HTRANS,        // transfer type
   output HREADYOUT,           // ready output to AHB Master
   output [1:0] HRESP,         // transfer response to AHB Master
   output [31:0] HRDATA,       // read data to AHB Master
 
   input  PCLK,
   input  PRESETn,             // active low reset
   output [31:0] PADDR,        // APB Address
   output PSEL,                // APB Peripheral Select
   output PENABLE,             // APB Peripheral Enable
   output PWRITE,              // APB Write Strobe
   output [31:0] PWDATA,       // APB Write Data bus
   input  [31:0] PRDATA        // APB Read Data bus... Requires a Mux external.
 );
 assign HRESP = `AHB_RESP_OKAY;
 
 // reg [31:0] HRDATA;
 reg        HREADYOUT;
 
 reg [31:0] PADDR;
 reg [31:0] PWDATA;
 reg PSEL;
 reg PWRITE;
 reg PENABLE;
 
 // HRDATA = PRDATA;  Just a pass through to make bridge IP-XACT work.
 assign HRDATA = PRDATA;
 
 // APB Bridge state machine:
 parameter APB_IDLE  = 0;
 parameter APB_C1    = 1;
 parameter APB_C2    = 2;
 
 reg [1:0] apbState;
 reg HSELdly;
 always @ (posedge HCLK or negedge HRESETn) begin
   if (!HRESETn) begin
       apbState  <= #1 APB_IDLE;
       HREADYOUT <= #1 1'b1;
       PENABLE   <= #1 1'b0;
       PADDR  <= #1 32'd0;
       PWDATA <= #1 32'd0;
       PWRITE <= #1 1'b0;
       PSEL <= #1 1'b0;
       HSELdly <= #1 1'b0;
   end
   else begin
     HSELdly <= #1 HSEL;
 
     case (apbState)
       APB_IDLE:   begin
         PENABLE   <= #1 1'b0;
         HREADYOUT <= #1 1'b1;
 
         if (HSEL & HTRANS[1] & HREADY) begin
             HREADYOUT <= #1 1'b0;// assert one wait state
             PADDR  <= #1 HADDR;  // register address & control when selected
             PWRITE <= #1 HWRITE;
             PSEL <= #1 1'b1;
             apbState  <= #1 APB_C1;
         end
       end
       APB_C1:     begin
         HREADYOUT <= #1 1'b1;
         PENABLE  <= #1 1'b1;
         apbState <= #1 APB_C2;
         PWDATA <= #1 HWDATA;// register data
       end
       APB_C2:     begin
         PENABLE  <= #1 1'b0;
         PSEL <= #1 1'b0;
 
         // handle case of back-to-back transfers
         if (HSEL & HTRANS[1] & HREADY) begin
           HREADYOUT <= #1 1'b0;// assert one wait state
           PADDR  <= #1 HADDR;  // register address & control when selected
           PWRITE <= #1 HWRITE;
           PSEL <= #1 1'b1;
           apbState  <= #1 APB_C1;
         end
         else
           apbState <= #1 APB_IDLE;
       end
       default:    apbState <= #1 APB_IDLE;
     endcase
   end
 end
 
 
 endmodule
 
 