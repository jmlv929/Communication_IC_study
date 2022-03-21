module CM1_JTAG(
  input         HCLK,  // AHB总线时钟
  input         rst_x, // 板级全局异步复位信号
  // JTAG inputs
  input         nTRST,       // JTAG reset
  input         TCK,         // JTAG clock
  input         TDI,         // JTAG data in
  inout         TMS,         // JTAG mode select
  // JTAG outputs
  output        TDO,         // JTAG data out
  output        nTDOEN,      // JTAG data enable
  output        RTCK,        // JTAG data out
  // Cortex-M1标准信号
  input         CM1_LOCKUP,
  input         CM1_HALTED,
  input         CM1_JTAGNSW,
  input         CM1_JTAGTOP,
  input         CM1_TDO,
  input         CM1_nTDOEN,
  input         CM1_SWDO,
  input         CM1_SWDOEN,
  input         CM1_SYSRESETREQ,
  output        CM1_SYSRESETn,
  input         CM1_DBGRESTARTED,
  output        CM1_EDBGRQ,
  output        CM1_DBGRESTART,
  output        CM1_DBGRESETn,
  output        CM1_nTRST,
  output        CM1_SWCLKTCK,
  output        CM1_SWDITMS,
  output        CM1_TDI      
);
reg rst_x_d0,rst_x_d1,rst_x_d2;
always @(posedge HCLK)
begin
  rst_x_d0<=rst_x;
  rst_x_d1<=rst_x_d0;
  rst_x_d2<=rst_x_d1;
end
reg CM1_SYSRESETREQ_d0,CM1_SYSRESETREQ_d1,CM1_SYSRESETREQ_d2;
always @(posedge HCLK or negedge CM1_DBGRESETn)
  if(!CM1_DBGRESETn) begin
    CM1_SYSRESETREQ_d0<=0;
    CM1_SYSRESETREQ_d1<=0;
    CM1_SYSRESETREQ_d2<=0;
  end else begin
    CM1_SYSRESETREQ_d0<=CM1_SYSRESETREQ;
    CM1_SYSRESETREQ_d1<=CM1_SYSRESETREQ_d0;
    CM1_SYSRESETREQ_d2<=CM1_SYSRESETREQ_d1;
  end
assign CM1_SYSRESETn = rst_x_d1 & rst_x_d2 
                     & ~CM1_SYSRESETREQ_d1 & ~CM1_SYSRESETREQ_d2;
assign CM1_DBGRESETn = rst_x_d1 & rst_x_d2 ;
assign CM1_EDBGRQ = 1'b0;
assign CM1_DBGRESTART = 1'b0;
/////////////////////////////////////
assign TDO       = (CM1_nTDOEN==1'b0) ? CM1_TDO : 1'bZ;
assign nTDOEN    = CM1_nTDOEN;
assign CM1_TDI   = TDI;
assign CM1_nTRST = nTRST;
assign TMS       = (CM1_SWDOEN==1'b1) ? CM1_SWDO : 1'bZ;
assign CM1_SWCLKTCK = TCK;
assign CM1_SWDITMS  = TMS ;// | CM1_JTAGNSW;

reg tck1,tck2,tck3;
// debug clock synchroniser
always @ (posedge HCLK or negedge nTRST)
  if (~nTRST) begin
      tck1    <= 1'b0;
      tck2    <= 1'b0;
      tck3    <= 1'b0;
  end else begin
      tck1    <= TCK;
      tck2    <= tck1;
      tck3    <= tck2;
  end
assign RTCK = tck3;
endmodule
   
   