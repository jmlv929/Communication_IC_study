module vJTAG_interface (
    input tck, tdi, aclr, ir_in,v_sdr, udr,
 
    output reg [6:0] LEDs,
    output reg tdo
 
);
 
reg DR0_bypass_reg; // Safeguard in case bad IR is sent through JTAG
reg [6:0] DR1; // Date, time and revision DR.  We could make separate Data Registers for each one, but
 
wire select_DR0 = !ir_in; // Default to 0, which is the bypass register
wire select_DR1 = ir_in; //Data Register 1 will collect the new LED Settings
 
always @ (posedge tck or posedge aclr)
begin
    if (aclr)
    begin
        DR0_bypass_reg <= 1'b0;
        DR1 <= 7'b000000;
    end
    else
    begin
        DR0_bypass_reg <= tdi; //Update the Bypass Register Just in case the incoming data is not sent to DR1
 
        if ( v_sdr )  // VJI is in Shift DR state
            if (select_DR1) //ir_in has been set to choose DR1
                    DR1 <= {tdi, DR1[6:1]}; // Shifting in (and out) the data
 
    end
end
 
//Maintain the TDO Continuity
always @ (*)
begin
    if (select_DR1)
        tdo <= DR1[0];
    else
        tdo <= DR0_bypass_reg;
end
 
//The udr signal will assert when the data has been transmitted and it's time to Update the DR
//  so copy it to the Output LED register.
//  Note that connecting the LED's to the DR1 register will cause an unwanted behavior as data is shifted through it
always @(udr)
begin
    LEDs <= DR1;
end
 
endmodule