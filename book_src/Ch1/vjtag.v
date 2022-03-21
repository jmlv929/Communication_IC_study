module vjtag (
input   clk,    // Internal clock
input   tdo_mux,// TDO before the negative edge flop
input   bypass, // JTAG instruction=BYPASS
input   tck,    // clock input
input   trst_n, // optional async reset active low
input   tms,    // Test Mode Select
input   tdi,    // Test Data In

output reg tdo, // Test Data Out
output reg tdo_enb,//Test Data Out tristate enable

output  tdi_r1,   // TDI flopped on TCK.
output  tck_rise, // tck rate clock enable
output  captureDR,// JTAG state=CAPTURE_DR
output  shiftDR,  // JTAG state=SHIFT_DR
output  updateDR, // JTAG state=UPDATE_DR
output  captureIR,// JTAG state=CAPTURE_IR
output  shiftIR,  // JTAG state=SHIFT_IR
output  updateIR
);
reg     tck_r1,tck_r2,tck_r3; 
reg     tdi_f_local; //  local version
wire    tdo_enb_nxt; //  D input to TDO_ENB flop
wire    tdo_nxt; //  D input to TDO flop
wire    itck_rise; 
wire    tck_fall; 

reg     [3:0] state; //  current state
wire    a,b,c,d,a_nxt,b_nxt,c_nxt,d_nxt;
assign a = state[0];
assign b = state[1];
assign c = state[2]; 
assign d = state[3];

assign a_nxt=(~tms & ~c & a) |(tms & 	~b)|(tms & ~a)|(tms & 	d & c);
assign b_nxt=(~tms & b & ~a) |(~tms & ~c)|(~tms & ~d & b)|(~tms & ~d & ~a)|(tms & c & ~b)|(tms & d & c & a);
assign c_nxt=(c & ~b)|(c & a)|(tms & ~b);
assign d_nxt=(d & ~c)|(d & b)|(~tms & c & ~b)|(~d & c & ~b & ~a);

assign tdo_enb_nxt = state == 4'b0010 | state == 4'b1010 ? 1'b1 : 	1'b0; 
assign captureIR = state == 4'b1110 ? 1'b1 : 	1'b0; 
assign shiftIR = state == 4'b1010 ? 1'b1 : 	1'b0; 
assign updateIR = state == 4'b1101 ? 1'b1 : 1'b0; 
assign captureDR = state == 4'b0110 ? 1'b1 : 	1'b0; 
assign shiftDR = state == 4'b0010 ? 1'b1 : 	1'b0; 
assign updateDR = state == 4'b0101 ? 1'b1 :	1'b0; 
assign tdo_nxt = bypass == 1'b1  &  state == 4'b0010 ? tdi_f_local : 	tdo_mux; 
assign tdi_r1 = tdi_f_local; 

always @(posedge clk) begin : rtck_proc
  tck_r3 <= tck_r2;	
  tck_r2 <= tck_r1;	//synchronizers for edge detection
  tck_r1 <= tck;	
end
assign tck_rise = itck_rise; 
assign itck_rise = tck_r2  &  ~tck_r3; 
assign tck_fall = ~tck_r2  &  tck_r3; 

always @(posedge clk)
  if (trst_n == 1'b0)
     state <= 4'b1111;	
  else if (itck_rise == 1'b1)begin
     state <= {d_nxt, c_nxt, b_nxt, a_nxt};	
  end

always @(posedge clk)  
   if (trst_n == 1'b0)
      tdi_f_local <= 1'b0;	
   else if (itck_rise == 1'b1 ) begin
      tdi_f_local <= tdi;	
   end

always @(posedge clk)
  if (trst_n == 1'b0)begin
      tdo <= 1'b0;	
      tdo_enb <= 1'b0;	
   end
   else if (tck_fall == 1'b1 ) begin
      tdo <= tdo_nxt;	
      tdo_enb <= tdo_enb_nxt;	
   end

endmodule // module vjtag

