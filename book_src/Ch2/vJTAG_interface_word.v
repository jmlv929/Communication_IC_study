01 module vJTAG_interface (
02   input tck, tdi, aclr, ir_in,v_sdr, udr,
03 
04   output reg [6:0] LEDs,
05   output reg tdo
06 );
07 reg DR0_bypass_reg; // Safeguard in case bad IR is sent through JTAG
08 reg [6:0] DR1; // Date, time and revision DR.  We could make separate Data Registers for each one, but
09 
10 wire select_DR0 = !ir_in; // Default to 0, which is the bypass register
11 wire select_DR1 = ir_in; //Data Register 1 will collect the new LED Settings
12 
13 always @ (posedge tck or posedge aclr)
14   if (aclr)begin
15     DR0_bypass_reg <= 1'b0;
16     DR1 <= 7'b000000;
17   end else begin
18     DR0_bypass_reg <= tdi; //Update the Bypass Register Just in case the incoming data is not sent to DR1
19     if ( v_sdr )  // VJI is in Shift DR state
20       if (select_DR1) //ir_in has been set to choose DR1
21           DR1 <= {tdi, DR1[6:1]}; // Shifting in (and out) the data
22   end
23 //Maintain the TDO Continuity
24 always @ (*)
25   if (select_DR1)
26     tdo <= DR1[0];
27   else
28     tdo <= DR0_bypass_reg;
29 
30 // The udr signal will assert when the data has been transmitted and it's time to Update the DR
31 //  so copy it to the Output LED register.
32 //  Note that connecting the LED's to the DR1 register will cause an unwanted behavior as data is shifted through it
33 always @(udr)
34   LEDs <= DR1;
35 
36 endmodule